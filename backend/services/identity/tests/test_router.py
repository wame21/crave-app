"""
Pruebas de integración de /auth y /users contra el PostgreSQL del contenedor
(docker compose up -d --wait). Catalog se sustituye por FakeCatalog.
"""
import re
import uuid
from collections.abc import Iterator
from pathlib import Path

import psycopg
import pytest
from fastapi.testclient import TestClient

import main
from config import DATABASE_URL
from contracts.registry import get_catalog
from core.errors import ConflictError
from services.identity.provider import IdentityProvider
from tests.fakes import FakeCatalog

TEST_DOMAIN = "crave-tests.example.com"
API = "/api/v1"


def _new_email() -> str:
    return f"user-{uuid.uuid4().hex[:10]}@{TEST_DOMAIN}"


def _saved_roles(email: str) -> list[str]:
    with psycopg.connect(DATABASE_URL) as conn:
        return [role for (role,) in conn.execute("SELECT role FROM identity.users WHERE email = %s", (email,))]


def _user_id(email: str) -> int:
    with psycopg.connect(DATABASE_URL) as conn:
        return conn.execute("SELECT id_user FROM identity.users WHERE email = %s", (email,)).fetchone()[0]


@pytest.fixture(scope="module", autouse=True)
def borrar_usuarios_de_prueba() -> Iterator[None]:
    yield
    with psycopg.connect(DATABASE_URL) as conn:
        conn.execute("DELETE FROM identity.users WHERE email LIKE %s", (f"%@{TEST_DOMAIN}",))


@pytest.fixture
def catalog() -> FakeCatalog:
    return FakeCatalog()


@pytest.fixture
def client(catalog) -> Iterator[TestClient]:
    app = main.create_app()
    app.dependency_overrides[get_catalog] = lambda: catalog
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client


def _register_client(client, email, **overrides):
    body = {"profile_name": "Cliente de prueba", "email": email, "password": "123456", "confirm_password": "123456"}
    return client.post(f"{API}/auth/register/client", json={**body, **overrides})


def _register_owner(client, email):
    body = {
        "profile_name": "Dueño de prueba",
        "email": email,
        "password": "123456",
        "confirm_password": "123456",
        "restaurant_name": "Fonda de prueba",
        "food_type": "Mexicana",
    }
    return client.post(f"{API}/auth/register/owner", json=body)


def _auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


# ── Login ────────────────────────────────────────────────────
def test_login_de_un_usuario_del_seed(client):
    response = client.post(f"{API}/auth/login", json={"email": "ana@example.com", "password": "123456"})

    assert response.status_code == 200
    body = response.json()
    assert (body["role"], body["profile_name"], body["token_type"]) == ("Client", "Ana López", "bearer")


def test_contrasena_incorrecta_y_correo_inexistente_responden_el_mismo_401(client):
    wrong = client.post(f"{API}/auth/login", json={"email": "ana@example.com", "password": "incorrecta"})
    unknown = client.post(f"{API}/auth/login", json={"email": "nadie@example.com", "password": "123456"})

    assert wrong.status_code == unknown.status_code == 401
    assert wrong.json() == unknown.json() == {
        "error": {"code": "invalid_credentials", "message": "Correo o contraseña incorrectos"}
    }
    assert wrong.headers["WWW-Authenticate"] == "Bearer"


# ── Registro de cliente y perfil ─────────────────────────────
def test_registrar_cliente_y_consultar_su_perfil(client):
    email = _new_email()

    registered = _register_client(client, email)
    profile = client.get(f"{API}/users/me", headers=_auth(registered.json()["access_token"]))

    assert registered.status_code == 201
    assert profile.status_code == 200
    body = profile.json()
    assert (body["email"], body["role"], body["profile_name"]) == (email, "Client", "Cliente de prueba")
    assert "password_hash" not in body
    assert _saved_roles(email) == ["Client"]


def test_correo_repetido_responde_409(client):
    email = _new_email()
    _register_client(client, email)

    response = _register_client(client, email)

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "email_taken"


def test_contrasenas_distintas_responden_422(client):
    response = _register_client(client, _new_email(), confirm_password="otra")

    assert response.status_code == 422
    [detail] = response.json()["error"]["details"]
    assert detail["field"] == "body.confirm_password"
    assert "Las contraseñas no coinciden" in detail["message"]


def test_actualizar_el_perfil_propio(client):
    token = _register_client(client, _new_email()).json()["access_token"]

    updated = client.put(f"{API}/users/me", headers=_auth(token), json={"profile_name": "Nombre nuevo"})
    profile = client.get(f"{API}/users/me", headers=_auth(token))
    empty = client.put(f"{API}/users/me", headers=_auth(token), json={})

    assert updated.status_code == 200
    assert profile.json()["profile_name"] == "Nombre nuevo"
    assert empty.status_code == 422
    assert empty.json()["error"]["code"] == "business_rule_violation"


def test_el_perfil_requiere_token(client):
    response = client.get(f"{API}/users/me")

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


# ── Saga de registro de dueño ────────────────────────────────
def test_registrar_dueno_crea_su_restaurante_en_catalog(client, catalog):
    email = _new_email()

    response = _register_owner(client, email)

    assert response.status_code == 201
    owner_id = response.json()["user_id"]
    assert catalog.calls_to("create_for_owner") == [(owner_id, "Fonda de prueba", "Mexicana")]
    assert _saved_roles(email) == ["Owner"]


def test_si_catalog_falla_el_dueno_no_queda_registrado(client, catalog):
    catalog.fail_on("create_for_owner")
    email = _new_email()

    response = _register_owner(client, email)

    assert response.status_code == 500
    assert response.json()["error"]["code"] == "internal_error"
    assert _saved_roles(email) == []


def test_si_catalog_rechaza_el_restaurante_se_responde_su_error(client, catalog):
    catalog.fail_on("create_for_owner", ConflictError("El dueño ya tiene un restaurante"))
    email = _new_email()

    response = _register_owner(client, email)

    assert response.status_code == 409
    assert _saved_roles(email) == []


# ── Contrato y documentación ─────────────────────────────────
def test_get_public_profiles_solo_expone_datos_publicos():
    ana, carlos = _user_id("ana@example.com"), _user_id("carlos@example.com")

    profiles = IdentityProvider().get_public_profiles([ana, carlos, ana, 999_999_999])

    assert set(profiles) == {ana, carlos}
    assert profiles[ana].profile_name == "Ana López"
    assert set(profiles[ana].model_dump()) == {"id_user", "profile_name", "photo_url"}
    assert IdentityProvider().get_public_profiles([]) == {}


def test_swagger_documenta_las_cinco_rutas_con_tipos(client):
    paths = client.get("/openapi.json").json()["paths"]

    def schema(path, method, status):
        return paths[f"{API}{path}"][method]["responses"][status]["content"]["application/json"]["schema"]["$ref"]

    assert schema("/auth/login", "post", "200").endswith("/TokenResponse")
    assert schema("/auth/register/client", "post", "201").endswith("/TokenResponse")
    assert schema("/auth/register/owner", "post", "201").endswith("/TokenResponse")
    assert schema("/users/me", "get", "200").endswith("/UserProfile")
    assert schema("/users/me", "put", "200").endswith("/UserProfile")


def test_el_repositorio_solo_usa_el_esquema_identity():
    source = (Path(__file__).parents[1] / "repository.py").read_text()

    tables = re.findall(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+([\w.]+)", source)

    assert tables and all(table.startswith("identity.") for table in tables)
