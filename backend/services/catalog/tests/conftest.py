"""Fixtures de las pruebas de Catalog que escriben en PostgreSQL."""
import itertools
import random
from collections.abc import Iterator

import psycopg
import pytest

from config import DATABASE_URL

# Dueños ficticios para las pruebas (Catalog no comprueba que existan en Identity).
TEST_OWNER_BASE = 900_000_000
_owner_ids = itertools.count(TEST_OWNER_BASE + random.randrange(1_000_000) * 100)


@pytest.fixture
def new_owner_id() -> int:
    """Un id de dueño sin restaurante; el siguiente (+1) también está libre."""
    owner_id = next(_owner_ids)
    next(_owner_ids)
    return owner_id


@pytest.fixture(scope="session", autouse=True)
def borrar_restaurantes_de_prueba() -> Iterator[None]:
    yield
    with psycopg.connect(DATABASE_URL) as conn:
        conn.execute("DELETE FROM catalog.restaurants WHERE id_owner >= %s", (TEST_OWNER_BASE,))
