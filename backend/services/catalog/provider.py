"""
Implementación de `CatalogContract` sobre el esquema `catalog`.

Cada método usa su propia conexión y transacción (`database.connection()`):
la llamada es atómica y queda confirmada al volver, como pide el contrato.
"""
from typing import get_args

from contracts.catalog import OrderBy, RestaurantSummary
from core.errors import BusinessRuleError, NotFoundError
from database import connection
from services.catalog.repository import RestaurantRepository

_ORDER_BY_VALUES = get_args(OrderBy)


class CatalogProvider:
    """Lo que Catalog ofrece a los demás servicios (ver `contracts.catalog`)."""

    def exists(self, restaurant_id: int) -> bool:
        with connection() as conn:
            return RestaurantRepository(conn).exists(restaurant_id)

    def get_summaries(self, ids: list[int]) -> list[RestaurantSummary]:
        unique_ids = list(dict.fromkeys(ids))
        if not unique_ids:
            return []
        with connection() as conn:
            rows = RestaurantRepository(conn).get_summaries(unique_ids)
        by_id = {row["id_restaurant"]: row for row in rows}
        return [RestaurantSummary.model_validate(by_id[i]) for i in unique_ids if i in by_id]

    def list_active(self, limit: int, order_by: OrderBy) -> list[RestaurantSummary]:
        if not 1 <= limit <= 100:
            raise ValueError(f"limit debe estar entre 1 y 100, no {limit}")
        if order_by not in _ORDER_BY_VALUES:
            raise ValueError(f"order_by inválido: {order_by!r}")
        with connection() as conn:
            rows = RestaurantRepository(conn).list_active(limit, order_by)
        return [RestaurantSummary.model_validate(row) for row in rows]

    def create_for_owner(self, owner_id: int, name: str, food_type: str) -> int:
        if not name.strip() or not food_type.strip():
            raise BusinessRuleError("El nombre y el tipo de comida son obligatorios")
        with connection() as conn:
            return RestaurantRepository(conn).create(owner_id, name.strip(), food_type.strip())

    def delete(self, restaurant_id: int) -> None:
        with connection() as conn:
            RestaurantRepository(conn).delete(restaurant_id)

    def set_rating(self, restaurant_id: int, value: float) -> None:
        if not 0 <= value <= 5:
            raise ValueError(f"La calificación debe estar entre 0 y 5, no {value}")
        with connection() as conn:
            found = RestaurantRepository(conn).set_rating(restaurant_id, round(value, 2))
        if not found:
            raise NotFoundError("Restaurante no encontrado")
