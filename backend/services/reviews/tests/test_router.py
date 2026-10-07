"""
Pruebas de integración de /reviews contra el PostgreSQL del contenedor
(docker compose up -d --wait). Catalog e Identity se sustituyen por sus fakes,
salvo en las pruebas marcadas "con los servicios reales".
"""
import re
from collections.abc import Iterator
from pathlib import Path

import psycopg
import pytest
from fastapi.testclient import TestClient

import main
from config import DATABASE_URL
from contracts.registry import get_catalog, get_identity
from core.security import create_access_token
from services.catalog.provider import CatalogProvider
from services.identity.provider import IdentityProvider
from services.reviews import router as reviews_router
from tests.fakes import FakeCatalog, FakeIdentity

API = "/api/v1/reviews"


def _auth(user_id: int, role: str = "Client") -> dict[str, str]:
    token = create_access_token(user_id, f"{role.lower()}-{user_id}@crave-tests.example.com", role)
    return {"Authorization": f"Bearer {token}"}


def _sql_average(restaurant_id: int) -> float:
    with psycopg.connect(DATABASE_URL) as conn:
        [value] = conn.execute(
            "SELECT round(avg((rating_food + rating_service + rating_atmosphere) / 3.0), 2) "
            "FROM reviews.reviews WHERE id_restaurant = %s AND status = 'Approved'",
            (restaurant_id,),
        ).fetchone()
    return float(value or 0)


def _body(restaurant_id: int, food=5, service=4, atmosphere=4, **extra) -> dict:
    return {
        "id_restaurant": restaurant_id,
        "rating_food": food,
        "rating_service": service,
        "rating_atmosphere": atmosphere,
        "comment": "Muy bueno",
        **extra,
    }


@pytest.fixture
def ids(new_id):
    """Un restaurante y dos clientes nuevos, conocidos por los fakes."""
    return {"restaurant": new_id(), "ana": new_id(), "carlos": new_id()}


@pytest.fixture
def catalog(ids) -> FakeCatalog:
    catalog = FakeCatalog()
    catalog.add("Restaurante de prueba", id_restaurant=ids["restaurant"], food_type="Tacos")
    return catalog


@pytest.fixture
def identity(ids) -> FakeIdentity:
    identity = FakeIdentity()
    identity.add("Ana de prueba", id_user=ids["ana"])
    identity.add("Carlos de prueba", id_user=ids["carlos"], photo_url="https://img/carlos.png")
    return identity


@pytest.fixture
def client(catalog, identity) -> Iterator[TestClient]:
    app = main.create_app()
    app.dependency_overrides[get_catalog] = lambda: catalog
    app.dependency_overrides[get_identity] = lambda: identity
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client


# ── Publicar ─────────────────────────────────────────────────
def test_publicar_actualiza_la_calificacion_con_el_promedio_de_sql(client, catalog, ids):
    rid = ids["restaurant"]

    first = client.post(API, headers=_auth(ids["ana"]), json=_body(rid, 5, 5, 5))
    second = client.post(API, headers=_auth(ids["carlos"]), json=_body(rid, 4, 3, 2))

    assert first.status_code == second.status_code == 201
    assert first.json()["status"] == "Approved"
    assert catalog.calls_to("set_rating") == [(rid, 5.0), (rid, 4.0)]
    assert catalog.calls_to("set_rating")[-1][1] == _sql_average(rid)


@pytest.mark.parametrize("role, status", [("Owner", 403)])
def test_solo_los_clientes_publican(client, ids, role, status):
    assert client.post(API, headers=_auth(ids["ana"], role=role), json=_body(ids["restaurant"])).status_code == status
    assert client.post(API, json=_body(ids["restaurant"])).status_code == 401


def test_publicar_en_un_restaurante_inexistente(client, ids):
    response = client.post(API, headers=_auth(ids["ana"]), json=_body(999_999_999))

    assert response.status_code == 404


def test_calificacion_fuera_de_rango(client, ids):
    response = client.post(API, headers=_auth(ids["ana"]), json=_body(ids["restaurant"], food=6))

    assert response.status_code == 422
    assert response.json()["error"]["details"][0]["field"] == "body.rating_food"


def test_resenar_dos_veces_el_mismo_restaurante(client, ids):
    client.post(API, headers=_auth(ids["ana"]), json=_body(ids["restaurant"]))

    response = client.post(API, headers=_auth(ids["ana"]), json=_body(ids["restaurant"]))

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "review_exists"


def test_con_moderacion_la_resena_queda_pendiente(client, catalog, ids, monkeypatch):
    monkeypatch.setattr(reviews_router, "DEFAULT_STATUS", "Pending")
    rid = ids["restaurant"]

    created = client.post(API, headers=_auth(ids["ana"]), json=_body(rid))
    public = client.get(f"{API}/restaurant/{rid}").json()
    mine = client.get(f"{API}/me", headers=_auth(ids["ana"])).json()

    assert created.json()["status"] == "Pending"
    assert public["total"] == 0
    assert [r["status"] for r in mine["items"]] == ["Pending"]
    assert catalog.calls_to("set_rating") == [(rid, 0.0)]


# ── Listados ─────────────────────────────────────────────────
def test_resenas_de_un_restaurante_paginadas_y_con_autor(client, identity, ids):
    rid = ids["restaurant"]
    client.post(API, headers=_auth(ids["ana"]), json=_body(rid))
    client.post(API, headers=_auth(ids["carlos"]), json=_body(rid))
    identity.calls.clear()

    page = client.get(f"{API}/restaurant/{rid}", params={"limit": 1}).json()

    assert (page["total"], page["limit"], len(page["items"])) == (2, 1, 1)
    assert (page["items"][0]["client_name"], page["items"][0]["client_photo"]) == (
        "Carlos de prueba", "https://img/carlos.png",
    )
    assert len(identity.calls_to("get_public_profiles")) == 1


def test_mis_resenas_con_el_nombre_del_restaurante(client, ids):
    client.post(API, headers=_auth(ids["ana"]), json=_body(ids["restaurant"]))

    page = client.get(f"{API}/me", headers=_auth(ids["ana"])).json()

    assert [r["restaurant_name"] for r in page["items"]] == ["Restaurante de prueba"]


# ── Borrar ───────────────────────────────────────────────────
def test_borrar_la_resena_de_otro_usuario_responde_403(client, ids):
    review_id = client.post(API, headers=_auth(ids["carlos"]), json=_body(ids["restaurant"])).json()["id_review"]

    response = client.delete(f"{API}/{review_id}", headers=_auth(ids["ana"]))

    assert response.status_code == 403
    assert client.get(f"{API}/restaurant/{ids['restaurant']}").json()["total"] == 1


def test_el_autor_borra_su_resena_y_se_recalcula(client, catalog, ids):
    rid = ids["restaurant"]
    review_id = client.post(API, headers=_auth(ids["ana"]), json=_body(rid)).json()["id_review"]

    response = client.delete(f"{API}/{review_id}", headers=_auth(ids["ana"]))

    assert response.status_code == 204
    assert catalog.calls_to("set_rating")[-1] == (rid, 0.0)
    assert client.delete(f"{API}/{review_id}", headers=_auth(ids["ana"])).status_code == 404


# ── Con los servicios reales ─────────────────────────────────
def _seed_id(sql: str, value: str) -> int:
    with psycopg.connect(DATABASE_URL) as conn:
        return conn.execute(sql, (value,)).fetchone()[0]


def test_resenas_del_seed_con_los_servicios_reales(client):
    client.app.dependency_overrides[get_catalog] = CatalogProvider
    client.app.dependency_overrides[get_identity] = IdentityProvider
    taqueria = _seed_id("SELECT id_restaurant FROM catalog.restaurants WHERE name = %s", "Taquería El Güero")

    page = client.get(f"{API}/restaurant/{taqueria}").json()

    assert page["total"] == 2
    assert {r["client_name"] for r in page["items"]} == {"Ana López", "Carlos Ramírez"}


def test_publicar_y_borrar_actualiza_el_rating_real_en_catalog(client, new_id):
    client.app.dependency_overrides[get_catalog] = CatalogProvider
    client.app.dependency_overrides[get_identity] = IdentityProvider
    catalog = CatalogProvider()
    mariscos = _seed_id("SELECT id_restaurant FROM catalog.restaurants WHERE name = %s", "Mariscos La Ola")
    original = catalog.get_summaries([mariscos])[0].overall_rating
    client_id = new_id()
    try:
        review_id = client.post(API, headers=_auth(client_id), json=_body(mariscos, 5, 4, 3)).json()["id_review"]
        after_create = catalog.get_summaries([mariscos])[0].overall_rating
        expected = _sql_average(mariscos)
        client.delete(f"{API}/{review_id}", headers=_auth(client_id))
        after_delete = catalog.get_summaries([mariscos])[0].overall_rating

        assert after_create == expected == 4.0 != original
        assert after_delete == original
    finally:
        catalog.set_rating(mariscos, original)


def test_el_repositorio_no_toca_esquemas_ajenos():
    source = (Path(__file__).parents[1] / "repository.py").read_text()

    assert "catalog." not in source and "identity." not in source
    tables = re.findall(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+([\w.]+)", source)
    assert tables and all(table == "reviews.reviews" for table in tables)
