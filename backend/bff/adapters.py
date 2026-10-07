"""
Implementación de los puertos del BFF con los servicios de dominio, dentro
del mismo proceso. Cada llamada usa su propia conexión y transacción: si un
servicio falla, no arrastra a los demás.
"""
from contracts.catalog import CatalogContract
from contracts.identity import IdentityContract
from core.pagination import Page, PageParams
from database import connection
from services.catalog.repository import RestaurantRepository
from services.catalog.schemas import RestaurantDetail
from services.catalog.service import CatalogService
from services.favorites.repository import FavoriteRepository
from services.favorites.service import FavoritesService
from services.reviews.repository import ReviewRepository
from services.reviews.schemas import ReviewResponse
from services.reviews.service import ReviewsService


class CatalogAdapter:
    def get_detail(self, restaurant_id: int) -> RestaurantDetail:
        with connection() as conn:
            return CatalogService(RestaurantRepository(conn)).get(restaurant_id)


class ReviewsAdapter:
    def __init__(self, catalog: CatalogContract, identity: IdentityContract):
        self._catalog = catalog
        self._identity = identity

    def list_for_restaurant(self, restaurant_id: int, page: PageParams) -> Page[ReviewResponse]:
        with connection() as conn:
            service = ReviewsService(ReviewRepository(conn), self._catalog, self._identity)
            return service.list_for_restaurant(restaurant_id, page)


class FavoritesAdapter:
    def __init__(self, catalog: CatalogContract):
        self._catalog = catalog

    def is_favorite(self, client_id: int, restaurant_id: int) -> bool:
        with connection() as conn:
            return FavoritesService(FavoriteRepository(conn), self._catalog).status(client_id, restaurant_id).is_favorite
