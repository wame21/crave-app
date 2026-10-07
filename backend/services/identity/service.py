"""
Reglas de negocio del servicio Identity: login, registro y perfil propio.
"""
import logging
from functools import cache
from typing import Any, Optional, Protocol

from contracts.catalog import CatalogContract
from core.errors import BusinessRuleError, NotFoundError, UnauthorizedError
from core.security import create_access_token
from services.identity.password import hash_password, verify_password
from services.identity.schemas import (
    RegisterClientRequest,
    RegisterOwnerRequest,
    TokenResponse,
    UpdateProfileRequest,
    UserProfile,
)

logger = logging.getLogger(__name__)

INVALID_CREDENTIALS = "Correo o contraseña incorrectos"


class UserStore(Protocol):
    """Lo que el service necesita del repositorio (`UserRepository` o un fake)."""

    def get_by_email(self, email: str) -> Optional[dict[str, Any]]: ...
    def get_by_id(self, user_id: int) -> Optional[dict[str, Any]]: ...
    def create(self, *, profile_name: str, email: str, password_hash: str, role: str) -> dict[str, Any]: ...
    def update(self, user_id: int, fields: dict[str, Any]) -> Optional[dict[str, Any]]: ...
    def delete(self, user_id: int) -> None: ...
    def commit(self) -> None: ...


@cache
def _dummy_hash() -> str:
    # Si el correo no existe se compara contra este hash, para que el login
    # tarde lo mismo en ambos casos y no revele qué correos están registrados.
    return hash_password("crave-correo-inexistente")


class IdentityService:
    def __init__(self, users: UserStore):
        self._users = users

    def login(self, email: str, password: str) -> TokenResponse:
        """
        Lanza `UnauthorizedError` con el mismo mensaje si el correo no existe
        o la contraseña es incorrecta, sin revelar cuál de los dos falló.
        """
        user = self._users.get_by_email(email)
        password_hash = user["password_hash"] if user else _dummy_hash()
        if not verify_password(password, password_hash) or user is None:
            raise UnauthorizedError(INVALID_CREDENTIALS, code="invalid_credentials")
        return self._issue_token(user)

    def register_client(self, data: RegisterClientRequest) -> TokenResponse:
        """Lanza `ConflictError` si el correo ya está registrado."""
        return self._issue_token(self._create_user(data, role="Client"))

    def register_owner(self, data: RegisterOwnerRequest, catalog: CatalogContract) -> TokenResponse:
        """
        Saga de registro de dueño:
          1. Crea el usuario Owner y lo confirma.
          2. Pide a Catalog que cree su restaurante (`create_for_owner`).
          3. Si el paso 2 falla, borra el usuario (compensación) y relanza el error.

        Lanza `ConflictError` si el correo ya está registrado, y los errores de
        `create_for_owner` si Catalog rechaza el restaurante.
        """
        user = self._create_user(data, role="Owner")
        self._users.commit()
        try:
            catalog.create_for_owner(user["id_user"], data.restaurant_name, data.food_type)
        except Exception:
            self._compensate_owner(user["id_user"])
            raise
        return self._issue_token(user)

    def get_profile(self, user_id: int) -> UserProfile:
        user = self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundError("Usuario no encontrado")
        return UserProfile.model_validate(user)

    def update_profile(self, user_id: int, data: UpdateProfileRequest) -> UserProfile:
        fields = data.model_dump(exclude_none=True)
        if not fields:
            raise BusinessRuleError("No se proporcionaron campos para actualizar")
        user = self._users.update(user_id, fields)
        if user is None:
            raise NotFoundError("Usuario no encontrado")
        return UserProfile.model_validate(user)

    def _create_user(self, data: RegisterClientRequest, *, role: str) -> dict[str, Any]:
        return self._users.create(
            profile_name=data.profile_name,
            email=data.email,
            password_hash=hash_password(data.password),
            role=role,
        )

    def _compensate_owner(self, user_id: int) -> None:
        try:
            self._users.delete(user_id)
            self._users.commit()
        except Exception:
            # El error original es el que importa al cliente; este queda en el log.
            logger.exception("No se pudo compensar el registro del dueño %s", user_id)

    @staticmethod
    def _issue_token(user: dict[str, Any]) -> TokenResponse:
        token = create_access_token(user["id_user"], user["email"], user["role"])
        return TokenResponse(
            access_token=token,
            user_id=user["id_user"],
            role=user["role"],
            profile_name=user["profile_name"],
        )
