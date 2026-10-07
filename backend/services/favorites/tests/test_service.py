"""Pruebas unitarias del service de Favorites, con un repositorio en memoria y FakeCatalog."""
from datetime import datetime, timezone

import pytest

from core.errors import ConflictError, NotFoundError
from core.pagination import PageParams
from services.favorites.service import FavoritesService
from tests.fakes import FakeCatalog

ANA = 1


class FakeFavoriteRepository:
    """`FavoriteStore` en memoria."""

    def __init__(self):
        self.rows: list[dict] = []

    def list_by_client(self, client_id, limit, offset):
        rows = [r for r in reversed(self.rows) if r["id_client"] == client_id]
        return rows[offset : offset + limit], len(rows)

    def is_favorite(self, client_id, restaurant_id):
        return any(r["id_client"] == client_id and r["id_restaurant"] == restaurant_id for r in self.rows)

    def add(self, client_id, restaurant_id):
        if self.is_favorite(client_id, restaurant_id):
            raise ConflictError("El restaurante ya está en tus favoritos", code="already_favorite")
        row = {
            "id_favorite": len(self.rows) + 1,
            "id_client": client_id,
            "id_restaurant": restaurant_id,
            "created_at": datetime.now(timezone.utc),
        }
        self.rows.append(row)
        return row

    def remove(self, client_id, restaurant_id):
        before = len(self.rows)
        self.rows = [r for r in self.rows if not (r["id_client"] == client_id and r["id_restaurant"] == restaurant_id)]
        return len(self.rows) < before


@pytest.fixture
def catalog():
    catalog = FakeCatalog()
    catalog.add("Taquería El Güero", id_restaurant=10, food_type="Tacos", overall_rating=4.33, address="Roma Norte")
    catalog.add("Sushi Koi", id_restaurant=20, food_type="Sushi", overall_rating=5.0)
    return catalog


@pytest.fixture
def repo():
    return FakeFavoriteRepository()


@pytest.fixture
def service(repo, catalog):
    return FavoritesService(repo, catalog)


def test_agregar_un_favorito_devuelve_los_datos_del_restaurante(service):
    favorite = service.add(ANA, 10)

    assert (favorite.id_restaurant, favorite.restaurant_name, favorite.food_type, favorite.overall_rating, favorite.address) == (
        10, "Taquería El Güero", "Tacos", 4.33, "Roma Norte",
    )


def test_agregar_un_favorito_duplicado_responde_conflicto(service):
    service.add(ANA, 10)

    with pytest.raises(ConflictError) as exc:
        service.add(ANA, 10)
    assert exc.value.code == "already_favorite"


def test_no_se_puede_marcar_un_restaurante_inexistente(service, repo):
    with pytest.raises(NotFoundError):
        service.add(ANA, 99)

    assert repo.rows == []


def test_quitar_un_favorito(service):
    service.add(ANA, 10)

    service.remove(ANA, 10)

    assert not service.status(ANA, 10).is_favorite


def test_quitar_uno_que_no_era_favorito_responde_404(service):
    with pytest.raises(NotFoundError) as exc:
        service.remove(ANA, 10)
    assert exc.value.code == "not_favorite"


def test_estado_de_favorito(service):
    service.add(ANA, 20)

    assert service.status(ANA, 20).is_favorite
    assert not service.status(ANA, 10).is_favorite


def test_listar_con_los_datos_de_cada_restaurante_en_una_sola_llamada(service, catalog):
    service.add(ANA, 10)
    service.add(ANA, 20)
    service.add(2, 10)  # de otro cliente
    catalog.calls.clear()

    page = service.list_mine(ANA, PageParams(limit=20, offset=0))

    assert [(f.restaurant_name, f.overall_rating) for f in page.items] == [("Sushi Koi", 5.0), ("Taquería El Güero", 4.33)]
    assert page.total == 2
    assert catalog.calls == [("get_summaries", ([20, 10],))]


def test_si_un_restaurante_ya_no_existe_se_omite_en_lugar_de_fallar(service, catalog):
    service.add(ANA, 10)
    service.add(ANA, 20)
    catalog.delete(20)

    page = service.list_mine(ANA, PageParams(limit=20, offset=0))

    assert [f.restaurant_name for f in page.items] == ["Taquería El Güero"]
