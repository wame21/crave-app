"""Fixtures de las pruebas de Reviews que escriben en PostgreSQL."""
import itertools
import random
from collections.abc import Callable, Iterator

import psycopg
import pytest

from config import DATABASE_URL

# Ids lógicos ficticios de clientes y restaurantes: Reviews no lee sus
# tablas, solo los guarda; en las pruebas los resuelven FakeCatalog y FakeIdentity.
TEST_ID_BASE = 900_000_000
_ids = itertools.count(TEST_ID_BASE + random.randrange(1_000_000) * 100)


@pytest.fixture
def new_id() -> Callable[[], int]:
    return lambda: next(_ids)


@pytest.fixture(scope="session", autouse=True)
def borrar_resenas_de_prueba() -> Iterator[None]:
    yield
    with psycopg.connect(DATABASE_URL) as conn:
        conn.execute(
            "DELETE FROM reviews.reviews WHERE id_client >= %s OR id_restaurant >= %s",
            (TEST_ID_BASE, TEST_ID_BASE),
        )
