"""Pruebas unitarias del service de Catalog, con un repositorio en memoria."""
import pytest
from pydantic import ValidationError

from core.errors import BusinessRuleError, ForbiddenError, NotFoundError
from core.pagination import PageParams
from services.catalog.schemas import RestaurantUpdate
from services.catalog.service import CatalogService


class FakeRestaurantRepository:
    """`RestaurantStore` en memoria."""

    def __init__(self, rows):
        self.rows = {row["id_restaurant"]: row for row in rows}
        self.search_args = None

    def search(self, **kwargs):
        self.search_args = kwargs
        rows = list(self.rows.values())
        return rows[kwargs["offset"] : kwargs["offset"] + kwargs["limit"]], len(rows)

    def get(self, restaurant_id):
        return self.rows.get(restaurant_id)

    def get_by_owner(self, owner_id):
        return next((row for row in self.rows.values() if row["id_owner"] == owner_id), None)

    def categories(self):
        return ["Tacos", "Pizza"]

    def update(self, restaurant_id, fields):
        if restaurant_id not in self.rows:
            return None
        self.rows[restaurant_id] = {**self.rows[restaurant_id], **fields}
        return self.rows[restaurant_id]


def _row(restaurant_id, owner_id, name="Restaurante", **extra):
    return {
        "id_restaurant": restaurant_id,
        "id_owner": owner_id,
        "name": name,
        "food_type": "Tacos",
        "overall_rating": 4.5,
        "is_active": True,
        **extra,
    }


@pytest.fixture
def repo():
    return FakeRestaurantRepository([_row(1, 10, "Taquería"), _row(2, 20, "Pizzería"), _row(3, None, "Sushi")])


@pytest.fixture
def service(repo):
    return CatalogService(repo)


# ── Búsqueda ─────────────────────────────────────────────────
def test_la_busqueda_devuelve_una_pagina_con_el_total_real(service, repo):
    page = service.search(q="  taco  ", category="Tacos", sort="new", page=PageParams(limit=2, offset=0))

    assert [item.name for item in page.items] == ["Taquería", "Pizzería"]
    assert (page.total, page.limit, page.offset) == (3, 2, 0)
    assert repo.search_args == {"q": "taco", "category": "Tacos", "order_by": "new", "limit": 2, "offset": 0}


def test_una_busqueda_vacia_no_filtra_por_texto(service, repo):
    service.search(q="", category=None, sort="rating", page=PageParams(limit=20, offset=0))

    assert repo.search_args["q"] is None


# ── Detalle ──────────────────────────────────────────────────
def test_detalle_de_un_restaurante(service):
    assert service.get(2).name == "Pizzería"


def test_detalle_de_un_restaurante_inexistente(service):
    with pytest.raises(NotFoundError):
        service.get(99)


def test_mi_restaurante(service):
    assert service.get_owned_by(10).name == "Taquería"


def test_un_dueno_sin_restaurante(service):
    with pytest.raises(NotFoundError, match="No tienes un restaurante"):
        service.get_owned_by(30)


# ── Edición ──────────────────────────────────────────────────
def test_el_dueno_edita_solo_los_campos_enviados(service, repo):
    updated = service.update(1, 10, RestaurantUpdate(phone="55 1234 5678"))

    assert (updated.name, updated.phone) == ("Taquería", "55 1234 5678")


def test_un_dueno_no_puede_editar_un_restaurante_ajeno(service, repo):
    with pytest.raises(ForbiddenError):
        service.update(2, 10, RestaurantUpdate(name="Mío"))

    assert repo.rows[2]["name"] == "Pizzería"


def test_editar_un_restaurante_inexistente(service):
    with pytest.raises(NotFoundError):
        service.update(99, 10, RestaurantUpdate(name="Nuevo"))


def test_editar_sin_campos_es_una_regla_de_negocio(service):
    with pytest.raises(BusinessRuleError):
        service.update(1, 10, RestaurantUpdate())


def test_si_lo_borran_entre_la_lectura_y_la_escritura_responde_404(service, repo):
    repo.update = lambda restaurant_id, fields: None

    with pytest.raises(NotFoundError):
        service.update(1, 10, RestaurantUpdate(name="Nuevo"))


def test_categorias(service):
    assert service.categories().categories == ["Tacos", "Pizza"]


# ── Schema ───────────────────────────────────────────────────
def test_social_media_acepta_el_texto_json_que_envia_la_app():
    update = RestaurantUpdate(social_media='{"instagram": "@crave", "facebook": ""}')

    assert update.social_media == {"instagram": "@crave", "facebook": ""}


def test_social_media_vacio_no_se_actualiza():
    assert RestaurantUpdate(social_media="  ").model_dump(exclude_none=True) == {}


def test_social_media_invalido():
    with pytest.raises(ValidationError, match="objeto JSON"):
        RestaurantUpdate(social_media="{no es json")
