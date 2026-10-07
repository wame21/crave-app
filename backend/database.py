"""
Capa de acceso a datos: PostgreSQL con psycopg 3 y un pool de conexiones.

No hay un cliente de BD global para los routers: cada request recibe su propia
conexión mediante la dependencia `DbConn` (que usa `get_db()`), y los
repositorios la reciben como parámetro. En las pruebas se sustituye con
`app.dependency_overrides[get_db]`.

Los errores de psycopg se propagan tal cual: traducirlos a HTTP es tarea de
los repositorios y de `core/errors.py`.

Uso en un router:

    from database import DbConn, fetch_all

    @router.get("/")
    def listar(db: DbConn):
        return fetch_all(db, "SELECT * FROM catalog.restaurants WHERE is_active = %s", (True,))
"""
import threading
from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager, contextmanager
from typing import Annotated, Any

from fastapi import Depends, FastAPI
from psycopg import Connection
from psycopg.abc import Params, QueryNoTemplate
from psycopg.rows import DictRow, dict_row
from psycopg_pool import ConnectionPool

from config import DATABASE_URL

POOL_MIN_SIZE = 1
POOL_MAX_SIZE = 10
# Segundos que un request espera una conexión libre antes de PoolTimeout.
POOL_TIMEOUT = 10.0

_DictPool = ConnectionPool[Connection[DictRow]]

_pool: _DictPool | None = None
_pool_lock = threading.Lock()


def _get_pool() -> _DictPool:
    """Devuelve el pool del proceso; lo crea en el primer uso."""
    global _pool
    with _pool_lock:
        if _pool is None:
            _pool = ConnectionPool(
                DATABASE_URL,
                connection_class=Connection[DictRow],
                kwargs={"row_factory": dict_row},
                min_size=POOL_MIN_SIZE,
                max_size=POOL_MAX_SIZE,
                timeout=POOL_TIMEOUT,
                # Descarta conexiones muertas (p. ej. tras reiniciar el contenedor).
                check=_DictPool.check_connection,
                open=True,
            )
        return _pool


def open_pool() -> None:
    """
    Abre el pool y espera a que la BD responda.

    Lanza `psycopg_pool.PoolTimeout` si no hay conexión en `POOL_TIMEOUT`
    segundos, para que la app falle al arrancar y no en el primer request.
    """
    _get_pool().wait(timeout=POOL_TIMEOUT)


def close_pool() -> None:
    """Cierra el pool y sus conexiones. Es idempotente."""
    global _pool
    with _pool_lock:
        if _pool is not None:
            _pool.close()
            _pool = None


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Ciclo de vida del pool junto al de la app: `FastAPI(lifespan=lifespan)`."""
    open_pool()
    try:
        yield
    finally:
        close_pool()


@contextmanager
def connection() -> Iterator[Connection[DictRow]]:
    """
    Presta una conexión del pool fuera de un request, con su propia transacción:
    commit al salir del bloque o rollback si se lanza una excepción.

    La usan las implementaciones de los contratos (`contracts/`), cuyas
    llamadas son atómicas y no participan en la transacción de quien llama:

        with connection() as conn:
            fetch_all(conn, "SELECT ...")
    """
    with _get_pool().connection() as conn:
        yield conn


def get_db() -> Iterator[Connection[DictRow]]:
    """
    Presta una conexión del pool durante un request, dentro de una transacción.

    Si el endpoint termina bien hace commit; si lanza cualquier excepción
    (incluida `HTTPException`) hace rollback. En ambos casos devuelve la
    conexión al pool. Las filas se leen como `dict`.

    Úsala a través de `DbConn` y no con `Depends(get_db)`: ver `DbConn`.
    """
    with connection() as conn:
        yield conn


DbConn = Annotated[Connection[DictRow], Depends(get_db, scope="function")]
"""
Dependencia de FastAPI con la conexión del request.

`scope="function"` hace el commit antes de enviar la respuesta: un cliente que
recibe 201 y consulta enseguida ya ve lo que escribió. Todas las dependencias
que declaren `DbConn` en el mismo request comparten la misma conexión; no la
mezcles con `Depends(get_db)`, porque FastAPI la cachea aparte y abriría una
segunda conexión con otra transacción.
"""


def fetch_one(conn: Connection[Any], query: QueryNoTemplate, params: Params | None = None) -> DictRow | None:
    """
    Ejecuta `query` y devuelve la primera fila como `dict`, o `None` si no hay filas.

    Los valores van siempre en `params` (`%s` o `%(nombre)s`), nunca interpolados
    en `query`. Sirve también para `INSERT/UPDATE ... RETURNING`.
    """
    with conn.cursor(row_factory=dict_row) as cur:
        cur.execute(query, params)
        return cur.fetchone()


def fetch_all(conn: Connection[Any], query: QueryNoTemplate, params: Params | None = None) -> list[DictRow]:
    """Ejecuta `query` y devuelve todas las filas como lista de `dict` (vacía si no hay)."""
    with conn.cursor(row_factory=dict_row) as cur:
        cur.execute(query, params)
        return cur.fetchall()


def execute(conn: Connection[Any], query: QueryNoTemplate, params: Params | None = None) -> int:
    """Ejecuta una sentencia sin resultado (INSERT, UPDATE, DELETE) y devuelve las filas afectadas."""
    with conn.cursor() as cur:
        cur.execute(query, params)
        return cur.rowcount
