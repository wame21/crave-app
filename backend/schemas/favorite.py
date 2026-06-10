"""
Schemas Pydantic para favoritos.
"""
from typing import Optional
from pydantic import BaseModel


class FavoriteResponse(BaseModel):
    id_favorite: int
    id_client: int
    id_restaurant: int
    created_at: Optional[str] = None
    # Campos del restaurante (join)
    restaurant_name: Optional[str] = None
    food_type: Optional[str] = None
    overall_rating: Optional[float] = None
    address: Optional[str] = None
