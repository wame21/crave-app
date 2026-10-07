"""
Peticiones y respuestas HTTP del servicio Identity.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, ValidationInfo, field_validator

from core.security import Role


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterClientRequest(BaseModel):
    profile_name: str = Field(min_length=1)
    email: EmailStr
    password: str = Field(min_length=1)
    confirm_password: str

    @field_validator("confirm_password")
    @classmethod
    def _passwords_match(cls, value: str, info: ValidationInfo) -> str:
        if value != info.data.get("password"):
            raise ValueError("Las contraseñas no coinciden")
        return value


class RegisterOwnerRequest(RegisterClientRequest):
    restaurant_name: str = Field(min_length=1, description="Nombre del restaurante")
    food_type: str = Field(min_length=1, description='Categoría principal, p. ej. "Tacos"')


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    role: Role
    profile_name: str


class UserProfile(BaseModel):
    id_user: int
    profile_name: str
    email: EmailStr
    role: Role
    photo_url: Optional[str] = None
    created_at: Optional[datetime] = None


class UpdateProfileRequest(BaseModel):
    """Solo se actualizan los campos enviados."""

    profile_name: Optional[str] = Field(default=None, min_length=1)
    photo_url: Optional[str] = None
