"""
Composición de las pantallas Home y detalle de restaurante.

Tolera fallos parciales: si falla una parte secundaria (novedades, reseñas o
favoritos), la pantalla se devuelve sin ella y con un aviso en `warnings`,
en lugar de responder 500.
"""
import logging
from typing import Optional

from bff.ports import FavoritesPort, RestaurantsPort, ReviewsPort
from bff.schemas import HomeResponse, RestaurantCard, RestaurantInfo, RestaurantScreen, ReviewItem
from contracts.catalog import CatalogContract, RestaurantSummary
from core.pagination import Page, PageParams
from core.security import CurrentUser
from services.reviews.schemas import ReviewResponse

logger = logging.getLogger(__name__)

FEATURED, TOP_RATED, RECOMMENDED, NEWEST = 5, 10, 10, 10
# Restaurantes por rating de los que salen featured, top_rated y recommended.
RATING_SAMPLE = 100


def _cards(restaurants: list[RestaurantSummary]) -> list[RestaurantCard]:
    return [RestaurantCard.model_validate(r.model_dump()) for r in restaurants]


def _best_per_category(by_rating: list[RestaurantSummary]) -> list[RestaurantSummary]:
    """El primero (mejor calificado) de cada categoría, en orden de rating."""
    seen: set[str] = set()
    best = []
    for restaurant in by_rating:
        category = (restaurant.food_type or "").lower()
        if category and category not in seen:
            seen.add(category)
            best.append(restaurant)
    return best


def _review_item(review: ReviewResponse) -> ReviewItem:
    ratings = (review.rating_food, review.rating_service, review.rating_atmosphere)
    return ReviewItem(
        id_review=review.id_review,
        author_name=review.client_name,
        author_photo=review.client_photo,
        rating_food=review.rating_food,
        rating_service=review.rating_service,
        rating_atmosphere=review.rating_atmosphere,
        rating_average=round(sum(ratings) / 3, 2),
        comment=review.comment,
        photo_gallery=review.photo_gallery,
        created_at=review.created_at,
    )


class BffService:
    def __init__(
        self,
        catalog: CatalogContract,
        restaurants: RestaurantsPort,
        reviews: ReviewsPort,
        favorites: FavoritesPort,
    ):
        self._catalog = catalog
        self._restaurants = restaurants
        self._reviews = reviews
        self._favorites = favorites

    def home(self) -> HomeResponse:
        """featured y top_rated por rating, recommended uno por categoría y newest por fecha."""
        by_rating = self._catalog.list_active(limit=RATING_SAMPLE, order_by="rating")
        warnings = []
        try:
            newest = self._catalog.list_active(limit=NEWEST, order_by="new")
        except Exception:
            logger.warning("El BFF no pudo cargar las novedades del Home", exc_info=True)
            newest = []
            warnings.append("No se pudieron cargar las novedades")
        return HomeResponse(
            featured=_cards(by_rating[:FEATURED]),
            top_rated=_cards(by_rating[:TOP_RATED]),
            recommended=_cards(_best_per_category(by_rating)[:RECOMMENDED]),
            newest=_cards(newest),
            warnings=warnings,
        )

    def restaurant_screen(
        self, restaurant_id: int, user: Optional[CurrentUser], page: PageParams
    ) -> RestaurantScreen:
        """
        Restaurante, sus reseñas y, si hay sesión, si es favorito. Si el
        restaurante no existe lanza `NotFoundError`; los fallos de reseñas o
        favoritos se informan en `warnings`.
        """
        detail = self._restaurants.get_detail(restaurant_id)
        warnings = []

        reviews: Optional[Page[ReviewItem]] = None
        try:
            found = self._reviews.list_for_restaurant(restaurant_id, page)
            reviews = Page.create([_review_item(r) for r in found.items], total=found.total, params=page)
        except Exception:
            logger.warning("El BFF no pudo cargar las reseñas del restaurante %s", restaurant_id, exc_info=True)
            warnings.append("No se pudieron cargar las reseñas")

        is_favorite: Optional[bool] = None
        if user is not None:
            try:
                is_favorite = self._favorites.is_favorite(user.id, restaurant_id)
            except Exception:
                logger.warning("El BFF no pudo consultar el favorito del restaurante %s", restaurant_id, exc_info=True)
                warnings.append("No se pudo consultar si el restaurante es favorito")

        return RestaurantScreen(
            restaurant=RestaurantInfo.model_validate(detail.model_dump()),
            reviews=reviews,
            is_favorite=is_favorite,
            warnings=warnings,
        )
