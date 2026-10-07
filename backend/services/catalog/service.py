"""
Reglas de negocio del servicio Catalog: búsqueda, detalle y edición de restaurantes.
"""
from typing import Any, Optional, Protocol

from contracts.catalog import OrderBy, RestaurantSummary
from core.errors import BusinessRuleError, ForbiddenError, NotFoundError
from core.pagination import Page, PageParams
from services.catalog.schemas import CategoriesResponse, RestaurantDetail, RestaurantUpdate


class RestaurantStore(Protocol):
    """Lo que el service necesita del repositorio (`RestaurantRepository` o un fake)."""

    def search(
        self, *, q: Optional[str], category: Optional[str], order_by: OrderBy, limit: int, offset: int
    ) -> tuple[list[dict[str, Any]], int]: ...
    def get(self, restaurant_id: int) -> Optional[dict[str, Any]]: ...
    def get_by_owner(self, owner_id: int) -> Optional[dict[str, Any]]: ...
    def categories(self) -> list[str]: ...
    def update(self, restaurant_id: int, fields: dict[str, Any]) -> Optional[dict[str, Any]]: ...


class CatalogService:
    def __init__(self, restaurants: RestaurantStore):
        self._restaurants = restaurants

    def search(
        self, *, q: Optional[str], category: Optional[str], sort: OrderBy, page: PageParams
    ) -> Page[RestaurantSummary]:
        """Restaurantes activos filtrados por nombre o tipo (`q`) y categoría, con el total real."""
        rows, total = self._restaurants.search(
            q=q.strip() if q else None,
            category=category,
            order_by=sort,
            limit=page.limit,
            offset=page.offset,
        )
        items = [RestaurantSummary.model_validate(row) for row in rows]
        return Page.create(items, total=total, params=page)

    def get(self, restaurant_id: int) -> RestaurantDetail:
        row = self._restaurants.get(restaurant_id)
        if row is None:
            raise NotFoundError("Restaurante no encontrado")
        return RestaurantDetail.model_validate(row)

    def get_owned_by(self, owner_id: int) -> RestaurantDetail:
        row = self._restaurants.get_by_owner(owner_id)
        if row is None:
            raise NotFoundError("No tienes un restaurante registrado")
        return RestaurantDetail.model_validate(row)

    def update(self, restaurant_id: int, owner_id: int, data: RestaurantUpdate) -> RestaurantDetail:
        """Solo el dueño del restaurante puede editarlo (si no, `ForbiddenError`)."""
        current = self._restaurants.get(restaurant_id)
        if current is None:
            raise NotFoundError("Restaurante no encontrado")
        if current["id_owner"] != owner_id:
            raise ForbiddenError("No tienes permiso para editar este restaurante")
        fields = data.model_dump(exclude_none=True)
        if not fields:
            raise BusinessRuleError("No se proporcionaron campos para actualizar")
        row = self._restaurants.update(restaurant_id, fields)
        if row is None:  # lo borraron entre la lectura y la escritura
            raise NotFoundError("Restaurante no encontrado")
        return RestaurantDetail.model_validate(row)

    def categories(self) -> CategoriesResponse:
        return CategoriesResponse(categories=self._restaurants.categories())
