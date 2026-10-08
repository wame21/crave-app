"""
Errores de dominio y formato único de error de la API.

Toda respuesta de error tiene la forma:

    {"error": {"code": "not_found", "message": "Restaurante no encontrado"}}

Los servicios lanzan las excepciones de este módulo (nunca `HTTPException`)
y `register_error_handlers(app)` las traduce al código HTTP adecuado.
"""
import logging
from typing import Any, Optional

from fastapi import FastAPI, Request, status
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.routing import Match

logger = logging.getLogger(__name__)


# ──────────────────────────────────────────────────────────────
# Modelos del formato de error (para documentar en OpenAPI)
# ──────────────────────────────────────────────────────────────
class ErrorDetail(BaseModel):
    """Detalle de un campo inválido (solo en errores de validación)."""

    field: str
    message: str


class ErrorBody(BaseModel):
    code: str
    message: str
    details: Optional[list[ErrorDetail]] = None


class ErrorResponse(BaseModel):
    error: ErrorBody


# Respuestas comunes a todas las rutas de /api/v1 (ver main.py).
COMMON_ERROR_RESPONSES: dict[int | str, dict[str, Any]] = {
    status.HTTP_400_BAD_REQUEST: {
        "model": ErrorResponse,
        "description": "El cuerpo de la petición no se puede leer (p. ej. no es JSON en UTF-8)",
    },
    status.HTTP_422_UNPROCESSABLE_CONTENT: {
        "model": ErrorResponse,
        "description": "Datos de entrada inválidos o regla de negocio incumplida",
    },
    status.HTTP_500_INTERNAL_SERVER_ERROR: {
        "model": ErrorResponse,
        "description": "Error interno del servidor",
    },
}


# ──────────────────────────────────────────────────────────────
# Excepciones de dominio
# ──────────────────────────────────────────────────────────────
class DomainError(Exception):
    """
    Base de los errores de dominio. Cada subclase fija su código HTTP y
    un `code` por defecto, que se puede sobrescribir para ser más
    específico (p. ej. `ConflictError("...", code="email_taken")`).
    """

    status_code: int = status.HTTP_400_BAD_REQUEST
    code: str = "bad_request"

    def __init__(self, message: str, *, code: Optional[str] = None):
        super().__init__(message)
        self.message = message
        if code is not None:
            self.code = code


class NotFoundError(DomainError):
    """El recurso solicitado no existe."""

    status_code = status.HTTP_404_NOT_FOUND
    code = "not_found"


class ConflictError(DomainError):
    """El recurso ya existe o choca con el estado actual."""

    status_code = status.HTTP_409_CONFLICT
    code = "conflict"


class ForbiddenError(DomainError):
    """El usuario está autenticado pero no tiene permiso."""

    status_code = status.HTTP_403_FORBIDDEN
    code = "forbidden"


class UnauthorizedError(DomainError):
    """Falta el token o es inválido."""

    status_code = status.HTTP_401_UNAUTHORIZED
    code = "unauthorized"


class BusinessRuleError(DomainError):
    """La petición es válida en forma pero incumple una regla de negocio."""

    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "business_rule_violation"


# ──────────────────────────────────────────────────────────────
# Handlers
# ──────────────────────────────────────────────────────────────
# Códigos para los HTTPException que lanzan FastAPI/Starlette
# (ruta inexistente, método no permitido, etc.).
_HTTP_STATUS_CODES = {
    400: "bad_request",
    401: "unauthorized",
    403: "forbidden",
    404: "not_found",
    405: "method_not_allowed",
    409: "conflict",
    413: "payload_too_large",
    415: "unsupported_media_type",
    429: "too_many_requests",
}


def error_response(
    status_code: int,
    code: str,
    message: str,
    *,
    details: Optional[list[ErrorDetail]] = None,
    headers: Optional[dict[str, str]] = None,
) -> JSONResponse:
    body = ErrorResponse(error=ErrorBody(code=code, message=message, details=details))
    return JSONResponse(
        status_code=status_code,
        content=jsonable_encoder(body, exclude_none=True),
        headers=headers,
    )


async def _domain_error_handler(request: Request, exc: DomainError) -> JSONResponse:
    headers = None
    if isinstance(exc, UnauthorizedError):
        headers = {"WWW-Authenticate": "Bearer"}
    return error_response(exc.status_code, exc.code, exc.message, headers=headers)


async def _validation_error_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    details = [
        ErrorDetail(
            field=".".join(str(part) for part in err.get("loc", ())),
            message=err.get("msg", ""),
        )
        for err in exc.errors()
    ]
    return error_response(
        status.HTTP_422_UNPROCESSABLE_CONTENT,
        "validation_error",
        "Los datos enviados no son válidos",
        details=details,
    )


_HTTP_METHODS = ("GET", "POST", "PUT", "PATCH", "DELETE")


def _allowed_methods(request: Request) -> Optional[str]:
    """
    Métodos que acepta el path de la petición. Starlette solo pone en `Allow`
    los de la primera ruta que coincide, y aquí cada método de un mismo path
    (p. ej. GET y PUT /restaurants/{id}) es una ruta distinta.
    """
    allowed = [
        method
        for method in _HTTP_METHODS
        if any(route.matches({**request.scope, "method": method})[0] == Match.FULL for route in request.app.router.routes)
    ]
    return ", ".join(allowed) or None


async def _http_exception_handler(
    request: Request, exc: StarletteHTTPException
) -> JSONResponse:
    code = _HTTP_STATUS_CODES.get(exc.status_code, "http_error")
    message = exc.detail if isinstance(exc.detail, str) else "Error en la petición"
    headers = exc.headers
    if exc.status_code == status.HTTP_405_METHOD_NOT_ALLOWED:
        allowed = _allowed_methods(request)
        if allowed:
            headers = {**(headers or {}), "Allow": allowed}
    return error_response(exc.status_code, code, message, headers=headers)


async def _unhandled_error_handler(request: Request, exc: Exception) -> JSONResponse:
    # El detalle va al log, nunca al cliente.
    logger.exception("Error no controlado en %s %s", request.method, request.url.path)
    return error_response(
        status.HTTP_500_INTERNAL_SERVER_ERROR,
        "internal_error",
        "Error interno del servidor",
    )


def register_error_handlers(app: FastAPI) -> None:
    """Registra en `app` los handlers que producen el formato único de error."""
    app.add_exception_handler(DomainError, _domain_error_handler)
    app.add_exception_handler(RequestValidationError, _validation_error_handler)
    app.add_exception_handler(StarletteHTTPException, _http_exception_handler)
    app.add_exception_handler(Exception, _unhandled_error_handler)
