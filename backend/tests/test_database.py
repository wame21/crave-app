"""
Pruebas de la capa de datos contra el PostgreSQL del contenedor (crave-postgres).

    docker compose up -d --wait
    pytest backend/tests/test_database.py
"""
import uuid
from collections.abc import Iterator
from decimal import Decimal
from typing import Annotated

import psycopg
import pytest
from fastapi import Depends, FastAPI, HTTPException
from fastapi.testclient import TestClient
from psycopg import errors, sql

from config import DATABASE_URL
from database import POOL_MAX_SIZE, DbConn, execute, fetch_all, fetch_one, lifespan


# ──────────────────────────────────────────────────────────────
# Helpers: fetch_one, fetch_all y execute
# ──────────────────────────────────────────────────────────────
@pytest.fixture
def platos(db_conn):
    """Tabla temporal con datos; desaparece con el rollback del test."""
    db_conn.execute(
        """
        CREATE TEMP TABLE platos (
            id serial PRIMARY KEY,
            nombre text NOT NULL UNIQUE,
            precio numeric(6, 2) NOT NULL
        )
        """
    )
    db_conn.execute(
        "INSERT INTO platos (nombre, precio) VALUES ('Tacos', 45), ('Pozole', 80), ('Tamales', 30)"
    )
    return db_conn


def test_fetch_one_devuelve_la_fila_como_dict(platos):
    fila = fetch_one(platos, "SELECT nombre, precio FROM platos WHERE nombre = %s", ("Pozole",))

    assert fila == {"nombre": "Pozole", "precio": Decimal("80.00")}


def test_fetch_one_sin_filas_devuelve_none(platos):
    assert fetch_one(platos, "SELECT * FROM platos WHERE nombre = %s", ("Sushi",)) is None


def test_fetch_one_devuelve_lo_que_indica_returning(platos):
    fila = fetch_one(
        platos,
        "INSERT INTO platos (nombre, precio) VALUES (%s, %s) RETURNING id, nombre",
        ("Mole", 95),
    )

    assert fila is not None
    assert fila["nombre"] == "Mole"
    assert isinstance(fila["id"], int)


def test_fetch_all_devuelve_lista_de_dicts(platos):
    filas = fetch_all(platos, "SELECT nombre FROM platos ORDER BY precio DESC LIMIT %s", (2,))

    assert filas == [{"nombre": "Pozole"}, {"nombre": "Tacos"}]


def test_fetch_all_sin_filas_devuelve_lista_vacia(platos):
    assert fetch_all(platos, "SELECT * FROM platos WHERE precio > %s", (1000,)) == []


def test_cada_consulta_es_independiente(platos):
    # Con el cliente REST, order() y limit() modificaban la misma instancia
    # y "novedades" salía ordenada por rating.
    mas_caro = fetch_all(platos, "SELECT nombre FROM platos ORDER BY precio DESC LIMIT 1")
    mas_nuevos = fetch_all(platos, "SELECT nombre FROM platos ORDER BY id DESC LIMIT 2")

    assert mas_caro == [{"nombre": "Pozole"}]
    assert mas_nuevos == [{"nombre": "Tamales"}, {"nombre": "Pozole"}]


def test_execute_devuelve_las_filas_afectadas(platos):
    afectadas = execute(platos, "UPDATE platos SET precio = precio + %s WHERE precio < %s", (5, 50))

    assert afectadas == 2


def test_acepta_parametros_con_nombre(platos):
    fila = fetch_one(
        platos,
        "SELECT nombre FROM platos WHERE precio BETWEEN %(min)s AND %(max)s",
        {"min": 40, "max": 50},
    )

    assert fila == {"nombre": "Tacos"}


def test_los_parametros_nunca_se_interpolan_en_el_sql(platos):
    malicioso = "x', 1); DROP TABLE platos; --"

    execute(platos, "INSERT INTO platos (nombre, precio) VALUES (%s, %s)", (malicioso, 1))

    assert fetch_one(platos, "SELECT nombre FROM platos WHERE nombre = %s", (malicioso,)) == {
        "nombre": malicioso
    }
    assert fetch_one(platos, "SELECT count(*) AS total FROM platos") == {"total": 4}


def test_los_errores_de_psycopg_se_propagan_sin_traducir(platos):
    with pytest.raises(errors.UniqueViolation):
        execute(platos, "INSERT INTO platos (nombre, precio) VALUES (%s, %s)", ("Tacos", 1))


# ──────────────────────────────────────────────────────────────
# get_db / DbConn: una conexión del pool por request
# ──────────────────────────────────────────────────────────────
@pytest.fixture
def tabla() -> Iterator[sql.Identifier]:
    """
    Tabla real (no temporal) para comprobar commits desde otra conexión.
    La restricción UNIQUE es diferida: un duplicado solo falla al hacer commit.
    """
    nombre = sql.Identifier(f"test_get_db_{uuid.uuid4().hex[:12]}")
    with psycopg.connect(DATABASE_URL, autocommit=True) as conn:
        conn.execute(
            sql.SQL("CREATE TABLE {} (nombre text UNIQUE DEFERRABLE INITIALLY DEFERRED)").format(nombre)
        )
    try:
        yield nombre
    finally:
        with psycopg.connect(DATABASE_URL, autocommit=True) as conn:
            conn.execute(sql.SQL("DROP TABLE IF EXISTS {}").format(nombre))


def _guardados(tabla: sql.Identifier) -> list[str]:
    """Lee la tabla desde una conexión aparte: solo ve lo que ya tiene commit."""
    with psycopg.connect(DATABASE_URL) as conn:
        filas = conn.execute(sql.SQL("SELECT nombre FROM {} ORDER BY nombre").format(tabla))
        return [nombre for (nombre,) in filas]


def _id_conexion(db: DbConn) -> int:
    """Dependencia de ejemplo, como la que crearía un repositorio."""
    return id(db)


@pytest.fixture
def client(tabla) -> Iterator[TestClient]:
    app = FastAPI(lifespan=lifespan)
    insertar = sql.SQL("INSERT INTO {} (nombre) VALUES (%s)").format(tabla)

    @app.post("/ok/{nombre}", status_code=201)
    def ok(nombre: str, db: DbConn):
        execute(db, insertar, (nombre,))
        return {"nombre": nombre}

    @app.post("/http-error/{nombre}")
    def http_error(nombre: str, db: DbConn):
        execute(db, insertar, (nombre,))
        raise HTTPException(status_code=409, detail="conflicto")

    @app.post("/excepcion/{nombre}")
    def excepcion(nombre: str, db: DbConn):
        execute(db, insertar, (nombre,))
        raise RuntimeError("fallo inesperado")

    @app.get("/fila")
    def fila(db: DbConn):
        return db.execute("SELECT 1 AS uno").fetchone()

    @app.get("/misma-conexion")
    def misma_conexion(db: DbConn, otra: Annotated[int, Depends(_id_conexion)]):
        return {"misma": id(db) == otra}

    with TestClient(app, raise_server_exceptions=False) as client:
        yield client


def test_get_db_hace_commit_si_el_endpoint_termina_bien(client, tabla):
    assert client.post("/ok/tacos").status_code == 201

    assert _guardados(tabla) == ["tacos"]


def test_get_db_hace_rollback_si_el_endpoint_lanza_http_exception(client, tabla):
    assert client.post("/http-error/tacos").status_code == 409

    assert _guardados(tabla) == []


def test_get_db_hace_rollback_si_el_endpoint_lanza_una_excepcion(client, tabla):
    assert client.post("/excepcion/tacos").status_code == 500

    assert _guardados(tabla) == []


def test_si_el_commit_falla_el_cliente_no_recibe_exito(client, tabla):
    # El commit ocurre antes de responder (scope="function"): si falla,
    # el cliente recibe 500 en lugar de un 201 de algo que no se guardó.
    assert client.post("/ok/tacos").status_code == 201

    assert client.post("/ok/tacos").status_code == 500
    assert _guardados(tabla) == ["tacos"]


def test_get_db_devuelve_las_conexiones_al_pool(client, tabla):
    # Si alguna conexión no volviera al pool, los requests se quedarían
    # esperando una libre hasta PoolTimeout.
    for i in range(POOL_MAX_SIZE * 2):
        assert client.post(f"/ok/plato-{i}").status_code == 201
        assert client.post(f"/http-error/fallido-{i}").status_code == 409

    assert len(_guardados(tabla)) == POOL_MAX_SIZE * 2


def test_las_filas_se_leen_como_dict(client):
    assert client.get("/fila").json() == {"uno": 1}


def test_las_dependencias_de_un_request_comparten_la_conexion(client):
    assert client.get("/misma-conexion").json() == {"misma": True}
