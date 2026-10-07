"""
Schemas Pydantic para reseñas.
"""
from typing import Optional, List
from pydantic import BaseModel, field_validator


class ReviewCreate(BaseModel):
    id_restaurant: int
    rating_food: int
    rating_service: int
    rating_atmosphere: int
    comment: Optional[str] = None
    photo_gallery: Optional[List[str]] = None

    @field_validator("rating_food", "rating_service", "rating_atmosphere")
    @classmethod
    def validate_rating(cls, v: int) -> int:
        if not 1 <= v <= 5:
            raise ValueError("La calificación debe estar entre 1 y 5")
        return v


class ReviewResponse(BaseModel):
    id_review: int
    id_client: Optional[int] = None
    id_restaurant: Optional[int] = None
    rating_food: Optional[int] = None
    rating_service: Optional[int] = None
    rating_atmosphere: Optional[int] = None
    comment: Optional[str] = None
    photo_gallery: Optional[List[str]] = None
    status: Optional[str] = None
    created_at: Optional[str] = None
    # Campos adicionales de joins:
    client_name: Optional[str] = None
    client_photo: Optional[str] = None
    restaurant_name: Optional[str] = None
