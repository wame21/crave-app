"""Pruebas del service y del endpoint /genie/chat, sin red."""
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

import main
from contracts.registry import get_catalog
from core.security import create_access_token
from services.catalog.provider import CatalogProvider
from services.genie.providers import FallbackProvider, GeminiProvider, KeywordProvider
from services.genie.router import get_ai_provider
from services.genie.service import GenieService
from tests.fakes import FakeCatalog

API = "/api/v1/genie/chat"
AUTH = {"Authorization": f"Bearer {create_access_token(1, 'ana@example.com', 'Client')}"}


@pytest.fixture
def catalog():
    catalog = FakeCatalog()
    catalog.add("Sushi Koi", food_type="Sushi", overall_rating=5.0)
    catalog.add("Café Tostado", food_type="Café", overall_rating=4.8)
    catalog.add("Otro Sushi", food_type="Sushi", overall_rating=3.0)
    catalog.add("Taquería", food_type="Tacos", overall_rating=4.0)
    catalog.add("Pizzería", food_type="Pizza", overall_rating=3.5)
    return catalog


# ── Service ──────────────────────────────────────────────────
def test_pide_los_restaurantes_a_catalog_por_su_contrato(catalog):
    GenieService(catalog, KeywordProvider()).chat("sushi")

    assert catalog.calls_to("list_active") == [(20, "rating")]


def test_sugiere_primero_los_de_la_categoria_pedida(catalog):
    response = GenieService(catalog, KeywordProvider()).chat("se me antoja sushi")

    assert "Sushi Koi" in response.reply
    assert [s.name for s in response.restaurant_suggestions] == ["Sushi Koi", "Otro Sushi"]


def test_sin_categoria_sugiere_los_tres_mejores(catalog):
    response = GenieService(catalog, KeywordProvider()).chat("tengo hambre")

    assert [s.name for s in response.restaurant_suggestions] == ["Sushi Koi", "Café Tostado", "Taquería"]


# ── Endpoint ─────────────────────────────────────────────────
@pytest.fixture
def client(catalog) -> Iterator[TestClient]:
    app = main.create_app()
    app.dependency_overrides[get_catalog] = lambda: catalog
    # El proveedor real, pero sin API key: tiene que responder el respaldo.
    app.dependency_overrides[get_ai_provider] = lambda: FallbackProvider(GeminiProvider(api_key=""), KeywordProvider())
    with TestClient(app) as client:
        yield client


def test_sin_gemini_api_key_el_endpoint_sigue_funcionando(client):
    response = client.post(API, headers=AUTH, json={"message": "  se me antoja sushi  "})

    body = response.json()
    assert response.status_code == 200
    assert "Sushi Koi" in body["reply"]
    assert body["restaurant_suggestions"][0] == {
        "id_restaurant": 1,
        "name": "Sushi Koi",
        "food_type": "Sushi",
        "description": None,
        "price_range": None,
        "address": None,
        "overall_rating": 5.0,
        "is_active": True,
    }


@pytest.mark.parametrize("message", ["", "   ", "x" * 501])
def test_mensajes_vacios_o_demasiado_largos_responden_422(client, message):
    response = client.post(API, headers=AUTH, json={"message": message})

    assert response.status_code == 422


def test_el_genio_requiere_token(client):
    assert client.post(API, json={"message": "sushi"}).status_code == 401


def test_el_proveedor_por_defecto_es_gemini_con_respaldo_y_lee_gemini_model(monkeypatch):
    from services.genie import router as genie_router

    monkeypatch.setenv("GEMINI_MODEL", "gemini-de-prueba")
    genie_router.default_provider.cache_clear()
    try:
        provider = genie_router.get_ai_provider()
    finally:
        genie_router.default_provider.cache_clear()

    assert isinstance(provider, FallbackProvider)
    assert isinstance(provider._primary, GeminiProvider) and provider._primary._model == "gemini-de-prueba"
    assert isinstance(provider._secondary, KeywordProvider)


def test_con_el_catalog_real_recomienda_del_seed(client):
    client.app.dependency_overrides[get_catalog] = CatalogProvider

    body = client.post(API, headers=AUTH, json={"message": "quiero mariscos"}).json()

    assert "Mariscos La Ola" in body["reply"]
    assert body["restaurant_suggestions"][0]["name"] == "Mariscos La Ola"
