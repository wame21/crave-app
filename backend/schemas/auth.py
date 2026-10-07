"""
Schemas Pydantic para autenticación.
"""
from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterClientRequest(BaseModel):
    profile_name: str
    email: EmailStr
    password: str
    confirm_password: str


class RegisterOwnerRequest(BaseModel):
    profile_name: str          # Nombre del dueño
    email: EmailStr
    password: str
    confirm_password: str
    restaurant_name: str       # Nombre del restaurante
    food_type: str             # Categoría principal (ej. "Tacos", "Pizza")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    role: str                  # "Client" | "Owner"
    profile_name: str
