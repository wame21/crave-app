"""
Acceso a datos del servicio Favorites. Solo trabaja sobre el esquema `favorites`.
"""
from typing import Any

from psycopg import Connection, errors

from core.errors import ConflictError
from database import execute, fetch_all, fetch_one


class FavoriteRepository:
    def __init__(self, conn: Connection[Any]):
        self._conn = conn

    def list_by_client(self, client_id: int, limit: int, offset: int) -> tuple[list[dict[str, Any]], int]:
        """Favoritos del cliente, del más reciente al más antiguo, y su total."""
        total = fetch_one(
            self._conn,
            "SELECT count(*) AS total FROM favorites.favorite_restaurants WHERE id_client = %s",
            (client_id,),
        )
        rows = fetch_all(
            self._conn,
            """
            SELECT id_favorite, id_client, id_restaurant, created_at
            FROM favorites.favorite_restaurants
            WHERE id_client = %s
            ORDER BY created_at DESC, id_favorite DESC
            LIMIT %s OFFSET %s
            """,
            (client_id, limit, offset),
        )
        return rows, total["total"] if total else 0

    def is_favorite(self, client_id: int, restaurant_id: int) -> bool:
        row = fetch_one(
            self._conn,
            """
            SELECT EXISTS (
                SELECT 1 FROM favorites.favorite_restaurants WHERE id_client = %s AND id_restaurant = %s
            ) AS found
            """,
            (client_id, restaurant_id),
        )
        return bool(row and row["found"])

    def add(self, client_id: int, restaurant_id: int) -> dict[str, Any]:
        """Marca el favorito. Lanza `ConflictError` si ya lo era."""
        try:
            row = fetch_one(
                self._conn,
                """
                INSERT INTO favorites.favorite_restaurants (id_client, id_restaurant)
                VALUES (%s, %s)
                RETURNING id_favorite, id_client, id_restaurant, created_at
                """,
                (client_id, restaurant_id),
            )
        except errors.UniqueViolation:
            raise ConflictError("El restaurante ya está en tus favoritos", code="already_favorite") from None
        assert row is not None  # INSERT ... RETURNING siempre devuelve la fila
        return row

    def remove(self, client_id: int, restaurant_id: int) -> bool:
        """Quita el favorito. Devuelve False si no lo era."""
        removed = execute(
            self._conn,
            "DELETE FROM favorites.favorite_restaurants WHERE id_client = %s AND id_restaurant = %s",
            (client_id, restaurant_id),
        )
        return removed > 0
