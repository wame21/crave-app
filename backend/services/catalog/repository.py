"""
Acceso a datos del servicio Catalog. Solo trabaja sobre el esquema `catalog`.
"""
from typing import Any, Optional

from psycopg import Connection, errors, sql
from psycopg.types.json import Jsonb

from contracts.catalog import OrderBy
from core.errors import BusinessRuleError, ConflictError
from database import execute, fetch_all, fetch_one

_DETAIL_COLUMNS = sql.SQL(
    "id_restaurant, id_owner, name, description, food_type, price_range, address, "
    "latitude, longitude, phone, social_media, opening_hours, overall_rating, is_active, created_at"
)
_SUMMARY_COLUMNS = sql.SQL(
    "id_restaurant, name, food_type, description, price_range, address, overall_rating, is_active"
)
_ORDER_BY: dict[str, sql.SQL] = {
    "rating": sql.SQL("overall_rating DESC, id_restaurant ASC"),
    "new": sql.SQL("created_at DESC, id_restaurant DESC"),
}

# Columnas que el dueño puede cambiar con PUT /restaurants/{id}.
UPDATABLE_COLUMNS = (
    "name", "description", "food_type", "price_range", "address",
    "latitude", "longitude", "phone", "social_media", "opening_hours",
)


def escape_like(text: str) -> str:
    """Escapa `\\`, `%` y `_` para buscar `text` literalmente con LIKE/ILIKE."""
    return text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def _unknown_category() -> BusinessRuleError:
    return BusinessRuleError(
        "La categoría no existe; usa una de GET /restaurants/categories", code="unknown_category"
    )


class RestaurantRepository:
    def __init__(self, conn: Connection[Any]):
        self._conn = conn

    # ── Lecturas ─────────────────────────────────────────────
    def search(
        self, *, q: Optional[str], category: Optional[str], order_by: OrderBy, limit: int, offset: int
    ) -> tuple[list[dict[str, Any]], int]:
        """Restaurantes activos que cumplen el filtro (una página) y el total real."""
        conditions = [sql.SQL("is_active")]
        params: list[Any] = []
        if q:
            pattern = f"%{escape_like(q)}%"
            conditions.append(sql.SQL("(name ILIKE %s ESCAPE '\\' OR food_type ILIKE %s ESCAPE '\\')"))
            params += [pattern, pattern]
        if category:
            conditions.append(sql.SQL("lower(food_type) = lower(%s)"))
            params.append(category)
        where = sql.SQL(" AND ").join(conditions)

        total = fetch_one(
            self._conn, sql.SQL("SELECT count(*) AS total FROM catalog.restaurants WHERE {}").format(where), params
        )
        rows = fetch_all(
            self._conn,
            sql.SQL("SELECT {} FROM catalog.restaurants WHERE {} ORDER BY {} LIMIT %s OFFSET %s").format(
                _SUMMARY_COLUMNS, where, _ORDER_BY[order_by]
            ),
            [*params, limit, offset],
        )
        return rows, total["total"] if total else 0

    def get(self, restaurant_id: int) -> Optional[dict[str, Any]]:
        return fetch_one(
            self._conn,
            sql.SQL("SELECT {} FROM catalog.restaurants WHERE id_restaurant = %s").format(_DETAIL_COLUMNS),
            (restaurant_id,),
        )

    def get_by_owner(self, owner_id: int) -> Optional[dict[str, Any]]:
        return fetch_one(
            self._conn,
            sql.SQL("SELECT {} FROM catalog.restaurants WHERE id_owner = %s").format(_DETAIL_COLUMNS),
            (owner_id,),
        )

    def categories(self) -> list[str]:
        rows = fetch_all(self._conn, "SELECT name FROM catalog.categories ORDER BY position")
        return [row["name"] for row in rows]

    def exists(self, restaurant_id: int) -> bool:
        row = fetch_one(
            self._conn,
            "SELECT EXISTS (SELECT 1 FROM catalog.restaurants WHERE id_restaurant = %s) AS found",
            (restaurant_id,),
        )
        return bool(row and row["found"])

    def get_summaries(self, ids: list[int]) -> list[dict[str, Any]]:
        return fetch_all(
            self._conn,
            sql.SQL("SELECT {} FROM catalog.restaurants WHERE id_restaurant = ANY(%s)").format(_SUMMARY_COLUMNS),
            (ids,),
        )

    def list_active(self, limit: int, order_by: OrderBy) -> list[dict[str, Any]]:
        return fetch_all(
            self._conn,
            sql.SQL("SELECT {} FROM catalog.restaurants WHERE is_active ORDER BY {} LIMIT %s").format(
                _SUMMARY_COLUMNS, _ORDER_BY[order_by]
            ),
            (limit,),
        )

    # ── Escrituras ───────────────────────────────────────────
    def update(self, restaurant_id: int, fields: dict[str, Any]) -> Optional[dict[str, Any]]:
        """Actualiza `fields` (solo columnas de `UPDATABLE_COLUMNS`). `None` si no existe."""
        unknown = set(fields) - set(UPDATABLE_COLUMNS)
        if unknown or not fields:
            raise ValueError(f"Columnas no actualizables: {sorted(unknown) or 'ninguna enviada'}")
        values = [Jsonb(value) if column == "social_media" else value for column, value in fields.items()]
        assignments = sql.SQL(", ").join(
            sql.SQL("{} = {}").format(sql.Identifier(column), sql.Placeholder()) for column in fields
        )
        query = sql.SQL("UPDATE catalog.restaurants SET {} WHERE id_restaurant = %s RETURNING {}").format(
            assignments, _DETAIL_COLUMNS
        )
        try:
            return fetch_one(self._conn, query, (*values, restaurant_id))
        except errors.ForeignKeyViolation:
            raise _unknown_category() from None

    def create(self, owner_id: int, name: str, food_type: str) -> int:
        """
        Crea un restaurante activo. Lanza `ConflictError` si el dueño ya tiene
        uno y `BusinessRuleError` si la categoría no existe.
        """
        try:
            row = fetch_one(
                self._conn,
                """
                INSERT INTO catalog.restaurants (id_owner, name, food_type)
                VALUES (%s, %s, %s)
                RETURNING id_restaurant
                """,
                (owner_id, name, food_type),
            )
        except errors.UniqueViolation:
            raise ConflictError("El dueño ya tiene un restaurante", code="owner_has_restaurant") from None
        except errors.ForeignKeyViolation:
            raise _unknown_category() from None
        assert row is not None  # INSERT ... RETURNING siempre devuelve la fila
        return row["id_restaurant"]

    def delete(self, restaurant_id: int) -> None:
        execute(self._conn, "DELETE FROM catalog.restaurants WHERE id_restaurant = %s", (restaurant_id,))

    def set_rating(self, restaurant_id: int, value: float) -> bool:
        """Fija `overall_rating`. Devuelve False si el restaurante no existe."""
        updated = execute(
            self._conn,
            "UPDATE catalog.restaurants SET overall_rating = %s WHERE id_restaurant = %s",
            (value, restaurant_id),
        )
        return updated > 0
