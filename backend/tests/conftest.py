"""
Fixtures compartidas por las pruebas del backend.

Las que usan la BD necesitan el contenedor de PostgreSQL levantado:
    docker compose up -d --wait
"""
import os
import sys
from collections.abc import Iterator
from pathlib import Path

import pytest

# El backend importa sus módulos sin paquete (`from config import ...`).
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
# Las pruebas no dependen del .env de cada desarrollador para el secreto JWT.
os.environ.setdefault("JWT_SECRET_KEY", "clave-solo-para-pruebas")

import psycopg  # noqa: E402
from psycopg.rows import DictRow, dict_row  # noqa: E402

from config import DATABASE_URL  # noqa: E402


@pytest.fixture
def db_conn() -> Iterator[psycopg.Connection[DictRow]]:
    """
    Conexión a la BD del contenedor dentro de una transacción que siempre se
    revierte al terminar el test: nada de lo que escriba queda guardado.

    Un `conn.commit()` dentro del test lanza `ProgrammingError`, y los bloques
    `with conn.transaction()` del código probado se convierten en savepoints.
    """
    try:
        conn = psycopg.Connection[DictRow].connect(
            DATABASE_URL, row_factory=dict_row, connect_timeout=3
        )
    except psycopg.OperationalError as exc:
        pytest.fail(
            "No se pudo conectar a PostgreSQL (DATABASE_URL). "
            f"Levanta el contenedor con `docker compose up -d --wait`.\n{exc}",
            pytrace=False,
        )
    with conn, conn.transaction(force_rollback=True):
        yield conn
