"""
Reglas de negocio del servicio Favorites.
"""
from typing import Any, Optional, Protocol

from contracts.catalog import CatalogContract, RestaurantSummary
from core.errors import NotFoundError
from core.pagination import Page, PageParams
from services.favorites.schemas import FavoriteResponse, FavoriteStatus


class FavoriteStore(Protocol):
    """Lo que el service necesita del repositorio (`FavoriteRepository` o un fake)."""

    def list_by_client(self, client_id: int, limit: int, offset: int) -> tuple[list[dict[str, Any]], int]: ...
    def is_favorite(self, client_id: int, restaurant_id: int) -> bool: ...
    def add(self, client_id: int, restaurant_id: int) -> dict[str, Any]: ...
    def remove(self, client_id: int, restaurant_id: int) -> bool: ...


def _with_restaurant(row: dict[str, Any], summary: Optional[RestaurantSummary]) -> FavoriteResponse:
    restaurant = (
        {
            "restaurant_name": summary.name,
            "food_type": summary.food_type,
            "overall_rating": summary.overall_rating,
            "address": summary.address,
        }
        if summary
        else {}
    )
    return FavoriteResponse.model_validate({**row, **restaurant})


class FavoritesService:
    def __init__(self, favorites: FavoriteStore, catalog: CatalogContract):
        self._favorites = favorites
        self._catalog = catalog

    def list_mine(self, client_id: int, page: PageParams) -> Page[FavoriteResponse]:
        """
        Favoritos con los datos de cada restaurante, pedidos a Catalog en una
        sola llamada. Los restaurantes que ya no existen en el catálogo se
        omiten; `total` cuenta los favoritos guardados.
        """
        rows, total = self._favorites.list_by_client(client_id, page.limit, page.offset)
        summaries = {s.id_restaurant: s for s in self._catalog.get_summaries([r["id_restaurant"] for r in rows])}
        items = [_with_restaurant(row, summaries[row["id_restaurant"]]) for row in rows if row["id_restaurant"] in summaries]
        return Page.create(items, total=total, params=page)

    def status(self, client_id: int, restaurant_id: int) -> FavoriteStatus:
        return FavoriteStatus(is_favorite=self._favorites.is_favorite(client_id, restaurant_id))

    def add(self, client_id: int, restaurant_id: int) -> FavoriteResponse:
        """Lanza `NotFoundError` si el restaurante no existe y `ConflictError` si ya era favorito."""
        if not self._catalog.exists(restaurant_id):
            raise NotFoundError("Restaurante no encontrado")
        row = self._favorites.add(client_id, restaurant_id)
        [summary] = self._catalog.get_summaries([restaurant_id]) or [None]
        return _with_restaurant(row, summary)

    def remove(self, client_id: int, restaurant_id: int) -> None:
        """Lanza `NotFoundError` si el restaurante no era favorito."""
        if not self._favorites.remove(client_id, restaurant_id):
            raise NotFoundError("El restaurante no estaba en tus favoritos", code="not_favorite")
