"""
Router de usuarios.
Endpoints: obtener perfil propio, actualizar perfil.
"""
from fastapi import APIRouter, Depends, HTTPException, status

from database import supabase
from schemas.user import UpdateProfileRequest, UserProfile
from utils.auth import get_current_user

router = APIRouter(prefix="/api/users", tags=["Usuarios"])


# ─────────────────────────────────────────────────────────────
# GET /api/users/me
# ─────────────────────────────────────────────────────────────
@router.get("/me", response_model=UserProfile, summary="Obtener perfil propio")
def get_my_profile(current_user: dict = Depends(get_current_user)):
    """
    Retorna la información del usuario autenticado.
    Requiere token JWT.
    """
    user_id = int(current_user["sub"])

    result = (
        supabase.table("users")
        .select("id_user, profile_name, email, role, photo_url, created_at")
        .eq("id_user", user_id)
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado",
        )

    return result.data


# ─────────────────────────────────────────────────────────────
# PUT /api/users/me
# ─────────────────────────────────────────────────────────────
@router.put("/me", response_model=UserProfile, summary="Actualizar perfil propio")
def update_my_profile(
    body: UpdateProfileRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Actualiza el nombre o foto de perfil del usuario autenticado.
    Solo se actualizan los campos enviados (parcial).
    """
    user_id = int(current_user["sub"])

    # Construir diccionario con solo los campos que no son None
    update_data = body.model_dump(exclude_none=True)

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se proporcionaron campos para actualizar",
        )

    result = (
        supabase.table("users")
        .update(update_data)
        .eq("id_user", user_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado",
        )

    return result.data[0]
