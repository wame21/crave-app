"""
Puertos del BFF: lo que necesita de cada servicio para componer las pantallas.

El BFF depende solo de estas interfaces (y de `CatalogContract`); `adapters.py`
las implementa con los servicios de dominio y las pruebas usan fakes.
"""
from typing import Protocol

from core.pagination import Page, PageParams
from services.catalog.schemas import RestaurantDetail
from services.reviews.schemas import ReviewResponse


class RestaurantsPort(Protocol):
    def get_detail(self, restaurant_id: int) -> RestaurantDetail:
        """Ficha completa del restaurante. Lanza `NotFoundError` si no existe."""
        ...


class ReviewsPort(Protocol):
    def list_for_restaurant(self, restaurant_id: int, page: PageParams) -> Page[ReviewResponse]:
        """Reseñas aprobadas del restaurante, con el nombre de cada autor."""
        ...


class FavoritesPort(Protocol):
    def is_favorite(self, client_id: int, restaurant_id: int) -> bool: ...
