"""Pruebas del formato único de error (core/errors.py)."""
import logging

import pytest
from fastapi import FastAPI, Query
from fastapi.testclient import TestClient

from core.errors import (
    BusinessRuleError,
    ConflictError,
    ForbiddenError,
    NotFoundError,
    UnauthorizedError,
    register_error_handlers,
)

DOMAIN_ERRORS = {
    "not-found": (NotFoundError("Restaurante no encontrado"), 404, "not_found"),
    "conflict": (ConflictError("Ya es favorito"), 409, "conflict"),
    "forbidden": (ForbiddenError("No es tu reseña"), 403, "forbidden"),
    "unauthorized": (UnauthorizedError("Se requiere autenticación"), 401, "unauthorized"),
    "business-rule": (BusinessRuleError("Ya reseñaste este lugar"), 422, "business_rule_violation"),
}


@pytest.fixture
def client():
    app = FastAPI()
    register_error_handlers(app)

    @app.get("/raise/{kind}")
    def raise_domain_error(kind: str):
        raise DOMAIN_ERRORS[kind][0]

    @app.get("/custom-code")
    def raise_with_custom_code():
        raise ConflictError("Ese correo ya está registrado", code="email_taken")

    @app.get("/validated")
    def validated(limit: int = Query(ge=1)):
        return {"limit": limit}

    @app.get("/boom")
    def boom():
        raise RuntimeError("detalle interno: password=1234")

    return TestClient(app, raise_server_exceptions=False)


@pytest.mark.parametrize("kind", DOMAIN_ERRORS)
def test_domain_error_maps_to_status_and_common_format(client, kind):
    error, status, code = DOMAIN_ERRORS[kind]

    response = client.get(f"/raise/{kind}")

    assert response.status_code == status
    assert response.json() == {"error": {"code": code, "message": error.message}}


def test_domain_error_code_can_be_more_specific(client):
    response = client.get("/custom-code")

    assert response.status_code == 409
    assert response.json() == {
        "error": {"code": "email_taken", "message": "Ese correo ya está registrado"}
    }


def test_unauthorized_includes_www_authenticate_header(client):
    response = client.get("/raise/unauthorized")

    assert response.headers["www-authenticate"] == "Bearer"


def test_validation_error_uses_common_format_with_field_details(client):
    response = client.get("/validated", params={"limit": 0})

    assert response.status_code == 422
    error = response.json()["error"]
    assert error["code"] == "validation_error"
    assert error["message"]
    assert [d["field"] for d in error["details"]] == ["query.limit"]


def test_missing_parameter_is_a_validation_error(client):
    response = client.get("/validated")

    assert response.status_code == 422
    assert response.json()["error"]["details"][0]["field"] == "query.limit"


def test_unknown_route_uses_common_format(client):
    response = client.get("/no-existe")

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


def test_method_not_allowed_uses_common_format(client):
    response = client.post("/custom-code")

    assert response.status_code == 405
    assert response.json()["error"]["code"] == "method_not_allowed"
    assert "GET" in response.headers["allow"]


def test_unhandled_error_returns_500_without_internal_details(client, caplog):
    with caplog.at_level(logging.ERROR, logger="core.errors"):
        response = client.get("/boom")

    assert response.status_code == 500
    assert response.json() == {
        "error": {"code": "internal_error", "message": "Error interno del servidor"}
    }
    assert "password" not in response.text
    # El detalle no se pierde: queda en el log del servidor.
    assert "password=1234" in caplog.text
