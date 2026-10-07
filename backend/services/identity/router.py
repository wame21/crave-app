"""
Rutas HTTP del servicio Identity: /auth (login y registro) y /users (perfil propio).
"""
from typing import Any

from fastapi import APIRouter, Depends, status

from contracts.catalog import CatalogContract
from contracts.registry import get_catalog, register_identity
from core.errors import ErrorResponse
from core.security import CurrentUser, get_current_user
from database import DbConn
from services.identity.provider import IdentityProvider
from services.identity.repository import UserRepository
from services.identity.schemas import (
    LoginRequest,
    RegisterClientRequest,
    RegisterOwnerRequest,
    TokenResponse,
    UpdateProfileRequest,
    UserProfile,
)
from services.identity.service import IdentityService

_ERROR_DESCRIPTIONS = {
    401: "Credenciales o token inválidos",
    404: "Usuario no encontrado",
    409: "El correo ya está registrado o el dueño ya tiene restaurante",
}


def _errors(*codes: int) -> dict[int | str, dict[str, Any]]:
    return {code: {"model": ErrorResponse, "description": _ERROR_DESCRIPTIONS[code]} for code in codes}


def get_identity_service(db: DbConn) -> IdentityService:
    return IdentityService(UserRepository(db))


auth_router = APIRouter(prefix="/auth", tags=["Autenticación"])
users_router = APIRouter(prefix="/users", tags=["Usuarios"])


@auth_router.post("/login", response_model=TokenResponse, summary="Iniciar sesión", responses=_errors(401))
def login(body: LoginRequest, service: IdentityService = Depends(get_identity_service)) -> TokenResponse:
    """
    Autentica a un cliente o dueño y devuelve su JWT. Un correo inexistente y
    una contraseña incorrecta responden el mismo 401.
    """
    return service.login(body.email, body.password)


@auth_router.post(
    "/register/client",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar cliente",
    responses=_errors(409),
)
def register_client(
    body: RegisterClientRequest,
    service: IdentityService = Depends(get_identity_service),
) -> TokenResponse:
    """Registra un usuario con rol Client y devuelve su JWT."""
    return service.register_client(body)


@auth_router.post(
    "/register/owner",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar dueño y su restaurante",
    responses=_errors(409),
)
def register_owner(
    body: RegisterOwnerRequest,
    service: IdentityService = Depends(get_identity_service),
    catalog: CatalogContract = Depends(get_catalog),
) -> TokenResponse:
    """
    Registra un usuario Owner y pide a Catalog que cree su restaurante. Si
    Catalog falla, el usuario se borra (compensación de la saga) y la
    respuesta es el error de Catalog.
    """
    return service.register_owner(body, catalog)


@users_router.get("/me", response_model=UserProfile, summary="Obtener perfil propio", responses=_errors(401, 404))
def get_my_profile(
    user: CurrentUser = Depends(get_current_user),
    service: IdentityService = Depends(get_identity_service),
) -> UserProfile:
    return service.get_profile(user.id)


@users_router.put("/me", response_model=UserProfile, summary="Actualizar perfil propio", responses=_errors(401, 404))
def update_my_profile(
    body: UpdateProfileRequest,
    user: CurrentUser = Depends(get_current_user),
    service: IdentityService = Depends(get_identity_service),
) -> UserProfile:
    """Actualiza el nombre o la foto del usuario autenticado; solo los campos enviados."""
    return service.update_profile(user.id, body)


router = APIRouter()
router.include_router(auth_router)
router.include_router(users_router)

register_identity(IdentityProvider())
