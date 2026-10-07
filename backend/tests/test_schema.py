"""
Pruebas del esquema de db/init contra el PostgreSQL del contenedor.

Los .sql solo se aplican al crear el volumen: si estas pruebas fallan en una
BD creada antes de un cambio de esquema, recréala con
    docker compose down -v && docker compose up -d --wait
"""
import psycopg
import pytest

from database import execute

INSERTAR_RESTAURANTE = "INSERT INTO catalog.restaurants (id_owner, name) VALUES (%s, %s)"
# Un id que no usa el seed, para no chocar con los dueños sembrados.
DUENO = 999_001


def test_un_dueno_no_puede_tener_dos_restaurantes(db_conn):
    execute(db_conn, INSERTAR_RESTAURANTE, (DUENO, "Primero"))

    with pytest.raises(psycopg.errors.UniqueViolation):
        execute(db_conn, INSERTAR_RESTAURANTE, (DUENO, "Segundo"))


def test_varios_restaurantes_pueden_no_tener_dueno(db_conn):
    execute(db_conn, INSERTAR_RESTAURANTE, (None, "Sin dueño 1"))
    execute(db_conn, INSERTAR_RESTAURANTE, (None, "Sin dueño 2"))
