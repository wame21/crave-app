"""
Peticiones y respuestas HTTP del servicio Reviews.
"""
from datetime import datetime
from typing import Annotated, Literal, Optional

from pydantic import BaseModel, Field

ReviewStatus = Literal["Pending", "Approved", "Rejected"]
Rating = Annotated[int, Field(ge=1, le=5, description="De 1 a 5")]


class ReviewCreate(BaseModel):
    id_restaurant: int
    rating_food: Rating
    rating_service: Rating
    rating_atmosphere: Rating
    comment: Optional[str] = Field(default=None, max_length=2000)
    photo_gallery: list[str] = Field(default_factory=list, max_length=10, description="URLs de fotos")


class ReviewResponse(BaseModel):
    id_review: int
    id_client: int
    id_restaurant: int
    rating_food: int
    rating_service: int
    rating_atmosphere: int
    comment: Optional[str] = None
    photo_gallery: list[str] = []
    status: ReviewStatus
    created_at: datetime
    # Datos de otros servicios, obtenidos por sus contratos:
    client_name: Optional[str] = Field(default=None, description="Del servicio Identity")
    client_photo: Optional[str] = Field(default=None, description="Del servicio Identity")
    restaurant_name: Optional[str] = Field(default=None, description="Del servicio Catalog")
