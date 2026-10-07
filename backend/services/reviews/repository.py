"""
Acceso a datos del servicio Reviews. Solo trabaja sobre el esquema `reviews`.
"""
from typing import Any, Optional

from psycopg import Connection

from database import execute, fetch_all, fetch_one


class ReviewRepository:
    def __init__(self, conn: Connection[Any]):
        self._conn = conn

    def list_approved_for_restaurant(self, restaurant_id: int, limit: int, offset: int) -> tuple[list[dict[str, Any]], int]:
        """Reseñas aprobadas de un restaurante, de la más reciente a la más antigua, y su total."""
        total = fetch_one(
            self._conn,
            "SELECT count(*) AS total FROM reviews.reviews WHERE id_restaurant = %s AND status = 'Approved'",
            (restaurant_id,),
        )
        rows = fetch_all(
            self._conn,
            """
            SELECT * FROM reviews.reviews
            WHERE id_restaurant = %s AND status = 'Approved'
            ORDER BY created_at DESC, id_review DESC
            LIMIT %s OFFSET %s
            """,
            (restaurant_id, limit, offset),
        )
        return rows, total["total"] if total else 0

    def list_by_client(self, client_id: int, limit: int, offset: int) -> tuple[list[dict[str, Any]], int]:
        """Todas las reseñas de un cliente (cualquier estado), de la más reciente a la más antigua."""
        total = fetch_one(
            self._conn, "SELECT count(*) AS total FROM reviews.reviews WHERE id_client = %s", (client_id,)
        )
        rows = fetch_all(
            self._conn,
            """
            SELECT * FROM reviews.reviews
            WHERE id_client = %s
            ORDER BY created_at DESC, id_review DESC
            LIMIT %s OFFSET %s
            """,
            (client_id, limit, offset),
        )
        return rows, total["total"] if total else 0

    def get(self, review_id: int) -> Optional[dict[str, Any]]:
        return fetch_one(self._conn, "SELECT * FROM reviews.reviews WHERE id_review = %s", (review_id,))

    def exists_for(self, client_id: int, restaurant_id: int) -> bool:
        row = fetch_one(
            self._conn,
            """
            SELECT EXISTS (
                SELECT 1 FROM reviews.reviews WHERE id_client = %s AND id_restaurant = %s
            ) AS found
            """,
            (client_id, restaurant_id),
        )
        return bool(row and row["found"])

    def create(
        self,
        *,
        client_id: int,
        restaurant_id: int,
        rating_food: int,
        rating_service: int,
        rating_atmosphere: int,
        comment: Optional[str],
        photo_gallery: list[str],
        status: str,
    ) -> dict[str, Any]:
        row = fetch_one(
            self._conn,
            """
            INSERT INTO reviews.reviews (
                id_client, id_restaurant, rating_food, rating_service,
                rating_atmosphere, comment, photo_gallery, status
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
            """,
            (client_id, restaurant_id, rating_food, rating_service, rating_atmosphere, comment, photo_gallery, status),
        )
        assert row is not None  # INSERT ... RETURNING siempre devuelve la fila
        return row

    def delete(self, review_id: int) -> None:
        execute(self._conn, "DELETE FROM reviews.reviews WHERE id_review = %s", (review_id,))

    def approved_average(self, restaurant_id: int) -> float:
        """Promedio de (comida + servicio + ambiente) / 3 de las reseñas aprobadas; 0 si no hay."""
        row = fetch_one(
            self._conn,
            """
            SELECT round(avg((rating_food + rating_service + rating_atmosphere) / 3.0), 2) AS rating
            FROM reviews.reviews
            WHERE id_restaurant = %s AND status = 'Approved'
            """,
            (restaurant_id,),
        )
        return float(row["rating"]) if row and row["rating"] is not None else 0.0

    def commit(self) -> None:
        """Confirma la transacción del request antes de avisar a otros servicios."""
        self._conn.commit()
