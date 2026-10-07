"""Pruebas de autenticación y roles (core/security.py)."""
from datetime import timedelta
from typing import Optional

import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from jose import jwt

from config import JWT_ALGORITHM, JWT_SECRET_KEY
from core.errors import UnauthorizedError, register_error_handlers
from core.security import (
    CurrentUser,
    create_access_token,
    decode_access_token,
    get_current_user,
    get_optional_user,
    require_role,
)


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


CLIENT_TOKEN = create_access_token(1, "cliente@crave.app", "Client")
OWNER_TOKEN = create_access_token(2, "duenio@crave.app", "Owner")


@pytest.fixture
def client():
    app = FastAPI()
    register_error_handlers(app)

    @app.get("/me")
    def me(user: CurrentUser = Depends(get_current_user)):
        return user

    @app.get("/owner-only")
    def owner_only(user: CurrentUser = Depends(require_role("Owner"))):
        return {"id": user.id}

    @app.get("/any-role")
    def any_role(user: CurrentUser = Depends(require_role("Client", "Owner"))):
        return {"id": user.id}

    @app.get("/optional")
    def optional(user: Optional[CurrentUser] = Depends(get_optional_user)):
        return {"id": user.id if user else None}

    return TestClient(app)


# ── Tokens ───────────────────────────────────────────────────
def test_token_round_trip_returns_typed_user():
    user = decode_access_token(create_access_token(7, "ana@crave.app", "Owner"))

    assert user == CurrentUser(id=7, email="ana@crave.app", role="Owner")


def test_token_keeps_the_sub_email_role_payload():
    payload = jwt.decode(CLIENT_TOKEN, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])

    assert (payload["sub"], payload["email"], payload["role"]) == ("1", "cliente@crave.app", "Client")


def test_create_token_rejects_unknown_role():
    with pytest.raises(ValueError):
        create_access_token(1, "x@crave.app", "Admin")


@pytest.mark.parametrize(
    "token",
    [
        create_access_token(1, "x@crave.app", "Client", expires_delta=timedelta(seconds=-1)),
        jwt.encode({"sub": "1", "email": "x@crave.app", "role": "Client"}, "otra-clave", algorithm="HS256"),
        jwt.encode({"sub": "1", "email": "x@crave.app"}, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM),
        jwt.encode({"sub": "abc", "email": "x@crave.app", "role": "Client"}, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM),
        "no-es-un-jwt",
    ],
    ids=["expirado", "otra-firma", "sin-rol", "sub-no-numerico", "basura"],
)
def test_invalid_tokens_are_unauthorized(token):
    with pytest.raises(UnauthorizedError):
        decode_access_token(token)


# ── get_current_user ─────────────────────────────────────────
def test_current_user_requires_a_token(client):
    response = client.get("/me")

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"
    assert response.headers["www-authenticate"] == "Bearer"


def test_current_user_rejects_non_bearer_scheme(client):
    response = client.get("/me", headers={"Authorization": "Basic abc"})

    assert response.status_code == 401


def test_current_user_rejects_invalid_token(client):
    response = client.get("/me", headers=_auth("no-es-un-jwt"))

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_token"


def test_current_user_is_typed(client):
    response = client.get("/me", headers=_auth(CLIENT_TOKEN))

    assert response.json() == {"id": 1, "email": "cliente@crave.app", "role": "Client"}


# ── require_role ─────────────────────────────────────────────
def test_require_role_allows_the_role(client):
    response = client.get("/owner-only", headers=_auth(OWNER_TOKEN))

    assert response.status_code == 200
    assert response.json() == {"id": 2}


def test_require_role_forbids_other_roles(client):
    response = client.get("/owner-only", headers=_auth(CLIENT_TOKEN))

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"


def test_require_role_without_token_is_unauthorized(client):
    assert client.get("/owner-only").status_code == 401


def test_require_role_accepts_several_roles(client):
    assert client.get("/any-role", headers=_auth(CLIENT_TOKEN)).status_code == 200
    assert client.get("/any-role", headers=_auth(OWNER_TOKEN)).status_code == 200


@pytest.mark.parametrize("roles", [(), ("Admin",), ("owner",)])
def test_require_role_rejects_bad_definitions(roles):
    with pytest.raises(ValueError):
        require_role(*roles)


# ── get_optional_user ────────────────────────────────────────
def test_optional_user_is_none_without_token(client):
    assert client.get("/optional").json() == {"id": None}


def test_optional_user_with_valid_token(client):
    assert client.get("/optional", headers=_auth(OWNER_TOKEN)).json() == {"id": 2}


def test_optional_user_with_invalid_token_is_unauthorized(client):
    assert client.get("/optional", headers=_auth("no-es-un-jwt")).status_code == 401
