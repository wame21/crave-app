"""
Pruebas de integración de /restaurants contra el PostgreSQL del contenedor
(docker compose up -d --wait).
"""
import re
import uuid
from collections.abc import Iterator
from pathlib import Path

import psycopg
import pytest
from fastapi.testclient import TestClient

import main
from config import DATABASE_URL
from contracts.registry import get_catalog
from core.security import create_access_token
from services.catalog.provider import CatalogProvider

API = "/api/v1/restaurants"
catalog = CatalogProvider()


def _query(sql: str, params=()) -> list[tuple]:
    with psycopg.connect(DATABASE_URL) as conn:
        return conn.execute(sql, params).fetchall()


def _user_id(email: str) -> int:
    return _query("SELECT id_user FROM identity.users WHERE email = %s", (email,))[0][0]


def _auth(user_id: int, role: str = "Owner") -> dict[str, str]:
    token = create_access_token(user_id, f"{role.lower()}-{user_id}@crave-tests.example.com", role)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def client() -> Iterator[TestClient]:
    with TestClient(main.create_app(), raise_server_exceptions=False) as client:
        yield client


# ── Listado y búsqueda ───────────────────────────────────────
def test_el_listado_devuelve_una_pagina_con_el_total_real(client):
    response = client.get(API, params={"limit": 3})

    body = response.json()
    [(active,)] = _query("SELECT count(*) FROM catalog.restaurants WHERE is_active")
    assert response.status_code == 200
    assert len(body["items"]) == 3
    assert (body["total"], body["limit"], body["offset"]) == (active, 3, 0)


def test_sort_new_ordena_del_mas_reciente_al_mas_antiguo(client):
    response = client.get(API, params={"sort": "new", "limit": 100})

    expected = _query(
        "SELECT id_restaurant FROM catalog.restaurants WHERE is_active "
        "ORDER BY created_at DESC, id_restaurant DESC LIMIT 100"
    )
    assert [item["id_restaurant"] for item in response.json()["items"]] == [row[0] for row in expected]


def test_por_defecto_ordena_por_rating(client):
    ratings = [item["overall_rating"] for item in client.get(API, params={"limit": 100}).json()["items"]]

    assert ratings == sorted(ratings, reverse=True)


def test_busca_por_nombre_o_por_tipo_de_comida(client):
    by_name = client.get(API, params={"q": "sushi"}).json()["items"]
    by_type = client.get(API, params={"q": "taco"}).json()["items"]

    assert "Sushi Koi" in [item["name"] for item in by_name]
    assert "Taquería El Güero" in [item["name"] for item in by_type]


@pytest.mark.parametrize("wildcard", ["%", "_", "\\"])
def test_los_comodines_del_usuario_se_buscan_literalmente(client, wildcard):
    body = client.get(API, params={"q": wildcard}).json()

    assert body["total"] == 0 and body["items"] == []


def test_filtra_por_categoria_sin_distinguir_mayusculas(client):
    body = client.get(API, params={"category": "café"}).json()

    assert body["total"] >= 1
    assert {item["food_type"] for item in body["items"]} == {"Café"}
    assert "Café Tostado" in [item["name"] for item in body["items"]]


def test_categorias_desde_la_base_de_datos(client):
    categories = client.get(f"{API}/categories").json()["categories"]

    assert categories[:2] == ["Tacos", "Pizza"]
    assert len(categories) == 10


def test_home_ya_no_es_parte_de_catalog(client):
    assert client.get(f"{API}/home").status_code != 200


# ── Detalle ──────────────────────────────────────────────────
def test_detalle_de_un_restaurante(client):
    [(sushi,)] = _query("SELECT id_restaurant FROM catalog.restaurants WHERE name = 'Sushi Koi'")

    body = client.get(f"{API}/{sushi}").json()

    assert (body["name"], body["price_range"], body["social_media"]) == (
        "Sushi Koi", "$$$", {"instagram": "@sushikoi.mx"},
    )


def test_detalle_de_un_restaurante_inexistente(client):
    response = client.get(f"{API}/999999999")

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


# ── Mi restaurante ───────────────────────────────────────────
def test_mi_restaurante_como_dueno(client):
    response = client.get(f"{API}/me", headers=_auth(_user_id("maria@example.com")))

    assert response.json()["name"] == "Taquería El Güero"


def test_mi_restaurante_requiere_rol_owner_y_token(client):
    as_client = client.get(f"{API}/me", headers=_auth(_user_id("ana@example.com"), role="Client"))
    anonymous = client.get(f"{API}/me")

    assert as_client.status_code == 403
    assert anonymous.status_code == 401


def test_un_dueno_sin_restaurante_recibe_404(client, new_owner_id):
    assert client.get(f"{API}/me", headers=_auth(new_owner_id)).status_code == 404


# ── Edición ──────────────────────────────────────────────────
def test_el_dueno_edita_su_restaurante_como_lo_hace_la_app(client, new_owner_id):
    restaurant_id = catalog.create_for_owner(new_owner_id, "Fonda de prueba", "Mexicana")
    body = {
        "name": "Fonda renovada",
        "phone": "55 0000 0000",
        "food_type": "Tacos",
        "social_media": '{"instagram": "@fonda", "facebook": ""}',
    }

    response = client.put(f"{API}/{restaurant_id}", headers=_auth(new_owner_id), json=body)
    detail = client.get(f"{API}/{restaurant_id}").json()

    assert response.status_code == 200
    assert (detail["name"], detail["phone"], detail["food_type"]) == ("Fonda renovada", "55 0000 0000", "Tacos")
    assert detail["social_media"] == {"instagram": "@fonda", "facebook": ""}


def test_un_dueno_no_puede_editar_un_restaurante_ajeno(client, new_owner_id):
    ajeno = catalog.create_for_owner(new_owner_id, "Restaurante ajeno", "Pizza")

    response = client.put(f"{API}/{ajeno}", headers=_auth(new_owner_id + 1), json={"name": "Robado"})

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"
    assert client.get(f"{API}/{ajeno}").json()["name"] == "Restaurante ajeno"


def test_un_cliente_no_puede_editar(client, new_owner_id):
    restaurant_id = catalog.create_for_owner(new_owner_id, "Solo dueños", "Pizza")

    response = client.put(f"{API}/{restaurant_id}", headers=_auth(new_owner_id, role="Client"), json={"name": "X"})

    assert response.status_code == 403


def test_editar_un_restaurante_inexistente(client, new_owner_id):
    response = client.put(f"{API}/999999999", headers=_auth(new_owner_id), json={"name": "X"})

    assert response.status_code == 404


@pytest.mark.parametrize(
    "body, code",
    [({}, "business_rule_violation"), ({"food_type": "Tailandesa"}, "unknown_category"), ({"price_range": "$$$$"}, "validation_error")],
)
def test_ediciones_invalidas_responden_422(client, new_owner_id, body, code):
    restaurant_id = catalog.create_for_owner(new_owner_id, "Validaciones", "Pizza")

    response = client.put(f"{API}/{restaurant_id}", headers=_auth(new_owner_id), json=body)

    assert response.status_code == 422
    assert response.json()["error"]["code"] == code


# ── Saga de registro de dueño con el Catalog real ────────────
def test_saga_de_registro_de_dueno_con_el_catalog_real(client):
    client.app.dependency_overrides[get_catalog] = lambda: catalog
    ok_email = f"owner-{uuid.uuid4().hex[:8]}@crave-tests.example.com"
    failing_email = f"owner-{uuid.uuid4().hex[:8]}@crave-tests.example.com"

    def register(email, food_type):
        return client.post(
            "/api/v1/auth/register/owner",
            json={
                "profile_name": "Dueño E2E",
                "email": email,
                "password": "123456",
                "confirm_password": "123456",
                "restaurant_name": "Restaurante E2E",
                "food_type": food_type,
            },
        )

    try:
        ok = register(ok_email, "Sushi")
        failing = register(failing_email, "Tailandesa")

        assert ok.status_code == 201
        owner_id = ok.json()["user_id"]
        assert _query("SELECT name FROM catalog.restaurants WHERE id_owner = %s", (owner_id,)) == [("Restaurante E2E",)]

        # Catalog rechaza la categoría: la saga borra al usuario que ya había creado.
        assert failing.status_code == 422
        assert failing.json()["error"]["code"] == "unknown_category"
        assert _query("SELECT 1 FROM identity.users WHERE email = %s", (failing_email,)) == []
    finally:
        with psycopg.connect(DATABASE_URL) as conn:
            ids = [row[0] for row in conn.execute(
                "SELECT id_user FROM identity.users WHERE email IN (%s, %s)", (ok_email, failing_email)
            )]
            conn.execute("DELETE FROM catalog.restaurants WHERE id_owner = ANY(%s)", (ids,))
            conn.execute("DELETE FROM identity.users WHERE id_user = ANY(%s)", (ids,))


def test_el_repositorio_solo_usa_el_esquema_catalog():
    source = (Path(__file__).parents[1] / "repository.py").read_text()

    tables = re.findall(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+([\w.]+)", source)

    assert tables and all(table.startswith("catalog.") for table in tables)
