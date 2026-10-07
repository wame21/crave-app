"""
Acceso a datos del servicio Identity. Solo trabaja sobre el esquema `identity`.
"""
from typing import Any, Optional

from psycopg import Connection, errors, sql

from core.errors import ConflictError
from database import execute, fetch_all, fetch_one

# Columnas que el propio usuario puede cambiar con PUT /users/me.
UPDATABLE_COLUMNS = ("profile_name", "photo_url")


class UserRepository:
    def __init__(self, conn: Connection[Any]):
        self._conn = conn

    def get_by_email(self, email: str) -> Optional[dict[str, Any]]:
        """Usuario con ese correo, incluido su `password_hash` (solo para el login)."""
        return fetch_one(
            self._conn,
            """
            SELECT id_user, profile_name, email, role, password_hash
            FROM identity.users
            WHERE email = %s
            """,
            (email,),
        )

    def get_by_id(self, user_id: int) -> Optional[dict[str, Any]]:
        return fetch_one(
            self._conn,
            """
            SELECT id_user, profile_name, email, role, photo_url, created_at
            FROM identity.users
            WHERE id_user = %s
            """,
            (user_id,),
        )

    def create(self, *, profile_name: str, email: str, password_hash: str, role: str) -> dict[str, Any]:
        """Crea el usuario. Lanza `ConflictError` si el correo ya está registrado."""
        try:
            row = fetch_one(
                self._conn,
                """
                INSERT INTO identity.users (profile_name, email, password_hash, role)
                VALUES (%s, %s, %s, %s)
                RETURNING id_user, profile_name, email, role, photo_url, created_at
                """,
                (profile_name, email, password_hash, role),
            )
        except errors.UniqueViolation:
            raise ConflictError("Este correo ya está registrado", code="email_taken") from None
        assert row is not None  # INSERT ... RETURNING siempre devuelve la fila
        return row

    def update(self, user_id: int, fields: dict[str, Any]) -> Optional[dict[str, Any]]:
        """Actualiza `fields` (solo columnas de `UPDATABLE_COLUMNS`). `None` si el usuario no existe."""
        unknown = set(fields) - set(UPDATABLE_COLUMNS)
        if unknown or not fields:
            raise ValueError(f"Columnas no actualizables: {sorted(unknown) or 'ninguna enviada'}")
        assignments = sql.SQL(", ").join(
            sql.SQL("{} = {}").format(sql.Identifier(column), sql.Placeholder()) for column in fields
        )
        query = sql.SQL(
            """
            UPDATE identity.users SET {}
            WHERE id_user = %s
            RETURNING id_user, profile_name, email, role, photo_url, created_at
            """
        ).format(assignments)
        return fetch_one(self._conn, query, (*fields.values(), user_id))

    def delete(self, user_id: int) -> None:
        execute(self._conn, "DELETE FROM identity.users WHERE id_user = %s", (user_id,))

    def get_public_profiles(self, ids: list[int]) -> list[dict[str, Any]]:
        """Solo datos públicos: nunca correo, rol ni contraseña."""
        return fetch_all(
            self._conn,
            "SELECT id_user, profile_name, photo_url FROM identity.users WHERE id_user = ANY(%s)",
            (ids,),
        )

    def commit(self) -> None:
        """Confirma lo hecho hasta ahora en la transacción (un paso de una saga)."""
        self._conn.commit()
