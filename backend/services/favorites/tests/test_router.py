"""
Pruebas de integración de /favorites contra el PostgreSQL del contenedor
(docker compose up -d --wait). Catalog se sustituye por FakeCatalog, salvo en
la prueba con los servicios reales.
"""
import re
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
from tests.fakes import FakeCatalog

API = "/api/v1/favorites"


def _auth(user_id: int) -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(user_id, f'cliente-{user_id}@crave-tests.example.com', 'Client')}"}


@pytest.fixture
def ids(new_id):
    return {"cliente": new_id(), "tacos": new_id(), "sushi": new_id()}


@pytest.fixture
def catalog(ids) -> FakeCatalog:
    catalog = FakeCatalog()
    catalog.add("Tacos de prueba", id_restaurant=ids["tacos"], food_type="Tacos", overall_rating=4.5)
    catalog.add("Sushi de prueba", id_restaurant=ids["sushi"], food_type="Sushi", overall_rating=3.0)
    return catalog


@pytest.fixture
def client(catalog) -> Iterator[TestClient]:
    app = main.create_app()
    app.dependency_overrides[get_catalog] = lambda: catalog
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client


def test_agregar_consultar_y_listar(client, ids):
    auth = _auth(ids["cliente"])

    added = client.post(f"{API}/{ids['tacos']}", headers=auth)
    status = client.get(f"{API}/{ids['tacos']}", headers=auth)
    other = client.get(f"{API}/{ids['sushi']}", headers=auth)
    page = client.get(API, headers=auth).json()

    assert added.status_code == 201
    assert added.json()["restaurant_name"] == "Tacos de prueba"
    assert status.json() == {"is_favorite": True}
    assert other.json() == {"is_favorite": False}
    assert page["total"] == 1
    assert [(f["restaurant_name"], f["food_type"], f["overall_rating"]) for f in page["items"]] == [
        ("Tacos de prueba", "Tacos", 4.5),
    ]


def test_agregar_un_duplicado_responde_409(client, ids):
    auth = _auth(ids["cliente"])
    client.post(f"{API}/{ids['tacos']}", headers=auth)

    response = client.post(f"{API}/{ids['tacos']}", headers=auth)

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "already_favorite"


def test_quitar_un_favorito_responde_204_y_quitar_uno_inexistente_404(client, ids):
    auth = _auth(ids["cliente"])
    client.post(f"{API}/{ids['tacos']}", headers=auth)

    removed = client.delete(f"{API}/{ids['tacos']}", headers=auth)
    again = client.delete(f"{API}/{ids['tacos']}", headers=auth)

    assert removed.status_code == 204
    assert again.status_code == 404
    assert again.json()["error"]["code"] == "not_favorite"


def test_marcar_un_restaurante_inexistente_responde_404(client, ids):
    response = client.post(f"{API}/999999999", headers=_auth(ids["cliente"]))

    assert response.status_code == 404


def test_un_restaurante_borrado_del_catalogo_se_omite(client, catalog, ids):
    auth = _auth(ids["cliente"])
    client.post(f"{API}/{ids['tacos']}", headers=auth)
    client.post(f"{API}/{ids['sushi']}", headers=auth)
    catalog.delete(ids["sushi"])

    page = client.get(API, headers=auth).json()

    assert [f["restaurant_name"] for f in page["items"]] == ["Tacos de prueba"]


def test_favoritos_requiere_token(client):
    assert client.get(API).status_code == 401


def test_favoritos_del_seed_con_el_catalog_real(client):
    client.app.dependency_overrides[get_catalog] = CatalogProvider
    with psycopg.connect(DATABASE_URL) as conn:
        [ana] = conn.execute("SELECT id_user FROM identity.users WHERE email = 'ana@example.com'").fetchone()

    page = client.get(API, headers=_auth(ana)).json()

    assert page["total"] == 3
    assert {f["restaurant_name"] for f in page["items"]} == {"Taquería El Güero", "Café Tostado", "Trattoria Bella Napoli"}


def test_el_repositorio_no_consulta_el_catalogo():
    source = (Path(__file__).parents[1] / "repository.py").read_text()

    assert "catalog." not in source
    tables = re.findall(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+([\w.]+)", source)
    assert tables and all(table == "favorites.favorite_restaurants" for table in tables)
