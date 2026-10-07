"""
Modelos de respuesta del BFF: la forma que necesitan las pantallas de la app,
no la de los servicios de dominio.
"""
from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field

from core.pagination import Page


class RestaurantCard(BaseModel):
    """Tarjeta de un restaurante en las secciones del Home."""

    id_restaurant: int
    name: str
    food_type: Optional[str] = None
    price_range: Optional[str] = None
    address: Optional[str] = None
    overall_rating: float


class HomeResponse(BaseModel):
    featured: list[RestaurantCard] = Field(description="Los 5 mejor calificados (carrusel)")
    top_rated: list[RestaurantCard] = Field(description="Los 10 mejor calificados")
    recommended: list[RestaurantCard] = Field(description="El mejor calificado de cada categoría, hasta 10")
    newest: list[RestaurantCard] = Field(description="Los 10 más recientes")
    warnings: list[str] = Field(default_factory=list, description="Secciones que no se pudieron cargar")


class RestaurantInfo(BaseModel):
    """Ficha del restaurante en la pantalla de detalle."""

    id_restaurant: int
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
    overall_rating: float


class ReviewItem(BaseModel):
    """Reseña tal como se muestra en el detalle."""

    id_review: int
    author_name: Optional[str] = None
    author_photo: Optional[str] = None
    rating_food: int
    rating_service: int
    rating_atmosphere: int
    rating_average: float = Field(description="Promedio de comida, servicio y ambiente")
    comment: Optional[str] = None
    photo_gallery: list[str] = []
    created_at: datetime


class RestaurantScreen(BaseModel):
    restaurant: RestaurantInfo
    reviews: Optional[Page[ReviewItem]] = Field(description="null si el servicio de reseñas falló")
    is_favorite: Optional[bool] = Field(description="null sin sesión o si el servicio de favoritos falló")
    warnings: list[str] = Field(default_factory=list, description="Partes que no se pudieron cargar")
