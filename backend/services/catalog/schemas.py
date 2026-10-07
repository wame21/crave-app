"""
Peticiones y respuestas HTTP del servicio Catalog.

Los listados usan `RestaurantSummary`, el mismo DTO del contrato
(`contracts.catalog`), para que la tarjeta de un restaurante sea igual en
cualquier servicio.
"""
import json
from datetime import datetime
from typing import Any, Literal, Optional

from pydantic import BaseModel, Field, field_validator

PriceRange = Literal["$", "$$", "$$$"]


class RestaurantDetail(BaseModel):
    """Ficha completa de un restaurante."""

    id_restaurant: int
    id_owner: Optional[int] = None
    name: str
    description: Optional[str] = None
    food_type: Optional[str] = None
    price_range: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    phone: Optional[str] = None
    social_media: Optional[dict[str, Any]] = None
    opening_hours: Optional[str] = None
    overall_rating: float = 0.0
    is_active: bool = True
    created_at: Optional[datetime] = None


class RestaurantUpdate(BaseModel):
    """Solo se actualizan los campos enviados."""

    name: Optional[str] = Field(default=None, min_length=1)
    description: Optional[str] = None
    food_type: Optional[str] = Field(default=None, description="Una de las de GET /restaurants/categories")
    price_range: Optional[PriceRange] = None
    address: Optional[str] = None
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    phone: Optional[str] = None
    social_media: Optional[dict[str, str]] = Field(
        default=None, description='Redes sociales, p. ej. {"instagram": "@crave"}'
    )
    opening_hours: Optional[str] = None

    @field_validator("social_media", mode="before")
    @classmethod
    def _accept_json_text(cls, value: Any) -> Any:
        # La app envía social_media como texto JSON; también se acepta un objeto.
        if isinstance(value, str):
            if not value.strip():
                return None
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                raise ValueError("social_media debe ser un objeto JSON") from None
        return value


class CategoriesResponse(BaseModel):
    categories: list[str]
