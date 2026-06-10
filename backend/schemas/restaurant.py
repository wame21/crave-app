"""
Schemas Pydantic para restaurantes.
"""
from typing import Optional, Any
from pydantic import BaseModel


class RestaurantBase(BaseModel):
    id_restaurant: int
    name: str
    description: Optional[str] = None
    food_type: Optional[str] = None
    price_range: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    phone: Optional[str] = None
    social_media: Optional[Any] = None   # JSON: {"instagram": "@...", "facebook": "@..."}
    opening_hours: Optional[str] = None
    overall_rating: Optional[float] = 0.0
    is_active: Optional[bool] = True
    id_owner: Optional[int] = None


class RestaurantUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    food_type: Optional[str] = None
    price_range: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    phone: Optional[str] = None
    social_media: Optional[Any] = None
    opening_hours: Optional[str] = None


class RestaurantCreate(BaseModel):
    name: str
    food_type: str
    id_owner: int
