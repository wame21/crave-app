"""
Punto de entrada del backend de Crave App.

Monta automáticamente bajo /api/v1 el `router` de:
  - cada servicio: `services/<dominio>/router.py`
  - el BFF: `bff/router.py`
Para agregar rutas no hace falta editar este archivo.

Al arrancar abre el pool de PostgreSQL y espera a la BD: si no responde,
el servidor no arranca (en lugar de fallar en el primer request).

Para iniciar el servidor:
    uvicorn main:app --reload --port 8000

Documentación interactiva disponible en:
    http://localhost:8000/docs
    http://localhost:8000/redoc
"""
import importlib
import importlib.util
import pkgutil
from collections.abc import Iterable
from typing import Any, Optional

from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware

import config
from core.errors import COMMON_ERROR_RESPONSES, register_error_handlers
from database import lifespan

API_V1_PREFIX = "/api/v1"
APP_VERSION = "1.0.0"


# ──────────────────────────────────────────────────────────────
# Descubrimiento de routers
# ──────────────────────────────────────────────────────────────
def _module_exists(name: str) -> bool:
    try:
        return importlib.util.find_spec(name) is not None
    except ModuleNotFoundError:  # no existe el paquete padre
        return False


def discover_routers(
    services_package: str = "services",
    extra_modules: Iterable[str] = ("bff.router",),
) -> list[APIRouter]:
    """
    Devuelve el `router` de cada `<services_package>/<dominio>/router.py`
    (en orden alfabético) y luego el de cada módulo de `extra_modules`.

    Se ignoran los subpaquetes sin `router.py` y los que empiezan por "_".
    Un router que falla al importarse detiene el arranque: no se oculta.
    """
    module_names: list[str] = []
    if _module_exists(services_package):
        package = importlib.import_module(services_package)
        for info in sorted(pkgutil.iter_modules(package.__path__), key=lambda m: m.name):
            name = f"{services_package}.{info.name}.router"
            if info.ispkg and not info.name.startswith("_") and _module_exists(name):
                module_names.append(name)
    module_names += [name for name in extra_modules if _module_exists(name)]

    routers = []
    for name in module_names:
        router = getattr(importlib.import_module(name), "router", None)
        if not isinstance(router, APIRouter):
            raise TypeError(f"{name} debe exportar `router = APIRouter(...)`")
        routers.append(router)
    return routers


# ──────────────────────────────────────────────────────────────
# CORS
# ──────────────────────────────────────────────────────────────
def cors_options(origins: list[str]) -> Optional[dict[str, Any]]:
    """
    Opciones de `CORSMiddleware` para los orígenes de CORS_ORIGINS, o
    `None` si no hay ninguno (no se permiten peticiones de otros orígenes).
    El comodín "*" solo se acepta sin credenciales.
    """
    if not origins:
        return None
    wildcard = "*" in origins
    return {
        "allow_origins": ["*"] if wildcard else origins,
        "allow_credentials": not wildcard,
        "allow_methods": ["*"],
        "allow_headers": ["*"],
    }


# ──────────────────────────────────────────────────────────────
# Aplicación
# ──────────────────────────────────────────────────────────────
def create_app() -> FastAPI:
    app = FastAPI(
        title="Crave App API",
        description=(
            "Backend de **Crave**, la app para descubrir y reseñar restaurantes. \n\n"
            "## Autenticación\n"
            "Los endpoints protegidos requieren un header:\n"
            "`Authorization: Bearer <tu_token_jwt>`\n\n"
            f"Obten tu token haciendo `POST {API_V1_PREFIX}/auth/login`.\n\n"
            "## Errores\n"
            'Todos los errores responden `{"error": {"code": "...", "message": "..."}}`.'
        ),
        version=APP_VERSION,
        contact={
            "name": "Equipo Crave",
            "email": "dev@crave-app.com",
        },
        lifespan=lifespan,
    )

    register_error_handlers(app)

    # CORS_ORIGINS lo define config.py como lista; getattr evita depender
    # del orden en que se integran las ramas de la Ola 1.
    options = cors_options(getattr(config, "CORS_ORIGINS", []))
    if options:
        app.add_middleware(CORSMiddleware, **options)

    for router in discover_routers():
        app.include_router(router, prefix=API_V1_PREFIX, responses=COMMON_ERROR_RESPONSES)

    @app.get("/", tags=["Health"])
    def root():
        """Verifica que el servidor está corriendo."""
        return {
            "status": "ok",
            "app": "Crave API",
            "version": APP_VERSION,
            "api": API_V1_PREFIX,
            "docs": "/docs",
        }

    @app.get("/health", tags=["Health"])
    def health_check():
        """Health check para monitoreo."""
        return {"status": "healthy"}

    return app


app = create_app()
