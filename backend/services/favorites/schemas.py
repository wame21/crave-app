"""
Respuestas HTTP del servicio Favorites.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class FavoriteResponse(BaseModel):
    id_favorite: int
    id_client: int
    id_restaurant: int
    created_at: datetime
    # Datos del restaurante, obtenidos de Catalog por su contrato:
    restaurant_name: Optional[str] = Field(default=None, description="Del servicio Catalog")
    food_type: Optional[str] = None
    overall_rating: Optional[float] = None
    address: Optional[str] = None


class FavoriteStatus(BaseModel):
    is_favorite: bool
