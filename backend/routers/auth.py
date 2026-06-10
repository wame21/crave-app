"""
Router de autenticación.
Endpoints: login, registro de cliente, registro de dueño de restaurante.
"""
from fastapi import APIRouter, HTTPException, status

from database import supabase
from schemas.auth import (
    LoginRequest,
    RegisterClientRequest,
    RegisterOwnerRequest,
    TokenResponse,
)
from utils.auth import create_access_token
from utils.password import hash_password, verify_password

router = APIRouter(prefix="/api/auth", tags=["Autenticación"])


# ─────────────────────────────────────────────────────────────
# POST /api/auth/login
# ─────────────────────────────────────────────────────────────
@router.post("/login", response_model=TokenResponse, summary="Iniciar sesión")
def login(body: LoginRequest):
    """
    Autentica a un usuario (cliente o dueño de restaurante).
    Retorna un JWT y los datos básicos del usuario.
    """
    # Buscar usuario por email
    result = (
        supabase.table("users")
        .select("*")
        .eq("email", body.email)
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
        )

    user = result.data

    # Verificar contraseña
    if not verify_password(body.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
        )

    # Generar token
    token = create_access_token(
        data={
            "sub": str(user["id_user"]),
            "email": user["email"],
            "role": user["role"],
        }
    )

    return TokenResponse(
        access_token=token,
        user_id=user["id_user"],
        role=user["role"],
        profile_name=user["profile_name"],
    )


# ─────────────────────────────────────────────────────────────
# POST /api/auth/register/client
# ─────────────────────────────────────────────────────────────
@router.post(
    "/register/client",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar cliente",
)
def register_client(body: RegisterClientRequest):
    """
    Registra un nuevo usuario con rol 'Client'.
    """
    if body.password != body.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Las contraseñas no coinciden",
        )

    # Verificar si el email ya existe
    existing = (
        supabase.table("users")
        .select("id_user")
        .eq("email", body.email)
        .execute()
    )
    if existing.data:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Este correo ya está registrado",
        )

    # Insertar nuevo usuario
    new_user = (
        supabase.table("users")
        .insert(
            {
                "profile_name": body.profile_name,
                "email": body.email,
                "password_hash": hash_password(body.password),
                "role": "Client",
            }
        )
        .execute()
    )

    user = new_user.data[0]

    token = create_access_token(
        data={
            "sub": str(user["id_user"]),
            "email": user["email"],
            "role": user["role"],
        }
    )

    return TokenResponse(
        access_token=token,
        user_id=user["id_user"],
        role=user["role"],
        profile_name=user["profile_name"],
    )


# ─────────────────────────────────────────────────────────────
# POST /api/auth/register/owner
# ─────────────────────────────────────────────────────────────
@router.post(
    "/register/owner",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar dueño de restaurante",
)
def register_owner(body: RegisterOwnerRequest):
    """
    Registra un nuevo usuario con rol 'Owner' y crea su restaurante.
    """
    if body.password != body.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Las contraseñas no coinciden",
        )

    # Verificar email duplicado
    existing = (
        supabase.table("users")
        .select("id_user")
        .eq("email", body.email)
        .execute()
    )
    if existing.data:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Este correo ya está registrado",
        )

    # Crear usuario Owner
    new_user_result = (
        supabase.table("users")
        .insert(
            {
                "profile_name": body.profile_name,
                "email": body.email,
                "password_hash": hash_password(body.password),
                "role": "Owner",
            }
        )
        .execute()
    )

    user = new_user_result.data[0]

    # Crear restaurante vinculado al nuevo owner
    supabase.table("restaurants").insert(
        {
            "id_owner": user["id_user"],
            "name": body.restaurant_name,
            "food_type": body.food_type,
            "is_active": True,
        }
    ).execute()

    token = create_access_token(
        data={
            "sub": str(user["id_user"]),
            "email": user["email"],
            "role": user["role"],
        }
    )

    return TokenResponse(
        access_token=token,
        user_id=user["id_user"],
        role=user["role"],
        profile_name=user["profile_name"],
    )
