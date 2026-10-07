"""
Autenticación y autorización: generación y validación de JWT, usuario
actual tipado y control de acceso por rol.

Uso en un router:

    @router.get("/me")
    def me(user: CurrentUser = Depends(get_current_user)): ...

    @router.put("/{id}")
    def update(id: int, user: CurrentUser = Depends(require_role("Owner"))): ...
"""
from collections.abc import Callable
from datetime import datetime, timedelta, timezone
from typing import Literal, Optional, get_args

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel, ConfigDict, ValidationError

from config import JWT_ALGORITHM, JWT_ACCESS_TOKEN_EXPIRE_MINUTES, JWT_SECRET_KEY
from core.errors import ForbiddenError, UnauthorizedError

Role = Literal["Client", "Owner"]
ROLES: tuple[str, ...] = get_args(Role)

# auto_error=False: la ausencia de token la resolvemos nosotros, para
# responder con el formato de error común (y para `get_optional_user`).
bearer_scheme = HTTPBearer(auto_error=False)


class CurrentUser(BaseModel):
    """Usuario autenticado, extraído del JWT."""

    model_config = ConfigDict(frozen=True)

    id: int
    email: str
    role: Role


def create_access_token(
    user_id: int,
    email: str,
    role: Role,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Genera un JWT firmado para el usuario."""
    if role not in ROLES:
        raise ValueError(f"Rol desconocido: {role!r}")
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "iat": now,
        "exp": now + (expires_delta or timedelta(minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES)),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> CurrentUser:
    """
    Valida un JWT y devuelve el usuario que contiene.
    Lanza `UnauthorizedError` si es inválido, expiró o le faltan datos.
    """
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return CurrentUser(
            id=payload.get("sub"),
            email=payload.get("email"),
            role=payload.get("role"),
        )
    except (JWTError, ValidationError):
        raise UnauthorizedError("Token inválido o expirado", code="invalid_token") from None


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> CurrentUser:
    """Dependencia: exige un token válido. Sin token o con uno inválido → 401."""
    if credentials is None:
        raise UnauthorizedError("Se requiere autenticación")
    return decode_access_token(credentials.credentials)


def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> Optional[CurrentUser]:
    """
    Dependencia para rutas públicas que se enriquecen si hay sesión.
    Sin token → `None`. Con un token inválido → 401, para que el cliente
    sepa que su sesión ya no sirve.
    """
    if credentials is None:
        return None
    return decode_access_token(credentials.credentials)


def require_role(*roles: Role) -> Callable[..., CurrentUser]:
    """
    Crea una dependencia que exige un usuario autenticado con alguno de
    los roles dados. Sin token → 401; con otro rol → 403.

        user: CurrentUser = Depends(require_role("Owner"))
    """
    if not roles:
        raise ValueError("require_role necesita al menos un rol")
    unknown = [role for role in roles if role not in ROLES]
    if unknown:
        raise ValueError(f"Roles desconocidos: {unknown}")
    allowed = frozenset(roles)

    def dependency(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
        if user.role not in allowed:
            raise ForbiddenError(f"Esta acción requiere el rol {' o '.join(roles)}")
        return user

    return dependency
