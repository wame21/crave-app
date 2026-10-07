"""
Schemas Pydantic para usuarios.
"""
from typing import Optional
from pydantic import BaseModel, EmailStr


class UserProfile(BaseModel):
    id_user: int
    profile_name: str
    email: EmailStr
    role: str
    photo_url: Optional[str] = None
    created_at: Optional[str] = None


class UpdateProfileRequest(BaseModel):
    profile_name: Optional[str] = None
    photo_url: Optional[str] = None
