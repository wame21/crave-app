"""
Pruebas de integración del BFF: con fakes para los fallos parciales y con
los servicios reales sobre el seed de PostgreSQL (docker compose up -d --wait).
"""
from collections.abc import Iterator

import psycopg
import pytest
from fastapi.testclient import TestClient

import main
from bff.router import get_restaurants_port, get_reviews_port
from config import DATABASE_URL
from contracts.registry import get_catalog, get_identity
from core.security import create_access_token
from services.catalog.provider import CatalogProvider
from services.identity.provider import IdentityProvider

API = "/api/v1/bff"


class BrokenReviews:
    def list_for_restaurant(self, restaurant_id, page):
        raise ConnectionError("El servicio de reseñas no responde")


def _id(sql: str, value: str) -> int:
    with psycopg.connect(DATABASE_URL) as conn:
        return conn.execute(sql, (value,)).fetchone()[0]


def _auth_as(email: str) -> dict[str, str]:
    user_id = _id("SELECT id_user FROM identity.users WHERE email = %s", email)
    return {"Authorization": f"Bearer {create_access_token(user_id, email, 'Client')}"}


@pytest.fixture
def client() -> Iterator[TestClient]:
    """La app con los servicios reales (Catalog e Identity registrados a mano)."""
    app = main.create_app()
    app.dependency_overrides[get_catalog] = CatalogProvider
    app.dependency_overrides[get_identity] = IdentityProvider
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client


def test_home_con_los_datos_del_seed(client):
    response = client.get(f"{API}/home")

    home = response.json()
    assert response.status_code == 200
    assert [len(home[key]) for key in ("featured", "top_rated", "newest")] == [5, 10, 10]
    assert home["featured"][0]["name"] == "Sushi Koi"
    assert home["newest"][0]["name"] == "Mariscos La Ola"
    ratings = [r["overall_rating"] for r in home["featured"]]
    assert ratings == sorted(ratings, reverse=True)
    assert len({r["food_type"] for r in home["recommended"]}) == len(home["recommended"])
    assert home["warnings"] == []


def test_detalle_con_sesion_trae_resenas_y_favorito(client):
    taqueria = _id("SELECT id_restaurant FROM catalog.restaurants WHERE name = %s", "Taquería El Güero")

    screen = client.get(f"{API}/restaurants/{taqueria}", headers=_auth_as("ana@example.com")).json()

    assert screen["restaurant"]["name"] == "Taquería El Güero"
    assert screen["restaurant"]["social_media"] == {"instagram": "@taqueriaelguero", "facebook": "taqueriaelguero"}
    assert screen["reviews"]["total"] == 2
    assert {r["author_name"] for r in screen["reviews"]["items"]} == {"Ana López", "Carlos Ramírez"}
    assert screen["is_favorite"] is True  # Ana tiene la Taquería en favoritos (seed)
    assert screen["warnings"] == []


def test_detalle_sin_sesion_no_calcula_favorito(client):
    taqueria = _id("SELECT id_restaurant FROM catalog.restaurants WHERE name = %s", "Taquería El Güero")

    screen = client.get(f"{API}/restaurants/{taqueria}").json()

    assert screen["is_favorite"] is None


def test_si_falla_el_servicio_de_resenas_responde_200_con_warnings(client):
    client.app.dependency_overrides[get_reviews_port] = BrokenReviews
    taqueria = _id("SELECT id_restaurant FROM catalog.restaurants WHERE name = %s", "Taquería El Güero")

    response = client.get(f"{API}/restaurants/{taqueria}", headers=_auth_as("ana@example.com"))

    assert response.status_code == 200
    assert response.json()["reviews"] is None
    assert response.json()["warnings"] == ["No se pudieron cargar las reseñas"]
    assert response.json()["is_favorite"] is True


def test_detalle_de_un_restaurante_inexistente(client):
    response = client.get(f"{API}/restaurants/999999999")

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


def test_un_token_invalido_responde_401(client):
    response = client.get(f"{API}/restaurants/1", headers={"Authorization": "Bearer basura"})

    assert response.status_code == 401


def test_las_respuestas_tienen_su_propia_forma(client):
    client.app.dependency_overrides[get_restaurants_port] = get_restaurants_port  # el real
    schemas = client.get("/openapi.json").json()["components"]["schemas"]

    assert {"HomeResponse", "RestaurantScreen", "RestaurantCard", "ReviewItem"} <= set(schemas)
    assert "rating_average" in schemas["ReviewItem"]["properties"]
