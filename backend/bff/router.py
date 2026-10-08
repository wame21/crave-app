"""
Rutas HTTP del BFF: /bff/home y /bff/restaurants/{id}.
"""
from typing import Optional

from fastapi import APIRouter, Depends

from bff.adapters import CatalogAdapter, FavoritesAdapter, ReviewsAdapter
from bff.ports import FavoritesPort, RestaurantsPort, ReviewsPort
from bff.schemas import HomeResponse, RestaurantScreen
from bff.service import BffService
from contracts.catalog import CatalogContract
from contracts.identity import IdentityContract
from contracts.registry import get_catalog, get_identity
from core.errors import ErrorResponse
from core.pagination import PageParams
from core.security import CurrentUser, get_optional_user


def get_restaurants_port() -> RestaurantsPort:
    return CatalogAdapter()


def get_reviews_port(
    catalog: CatalogContract = Depends(get_catalog),
    identity: IdentityContract = Depends(get_identity),
) -> ReviewsPort:
    return ReviewsAdapter(catalog, identity)


def get_favorites_port(catalog: CatalogContract = Depends(get_catalog)) -> FavoritesPort:
    return FavoritesAdapter(catalog)


def get_bff_service(
    catalog: CatalogContract = Depends(get_catalog),
    restaurants: RestaurantsPort = Depends(get_restaurants_port),
    reviews: ReviewsPort = Depends(get_reviews_port),
    favorites: FavoritesPort = Depends(get_favorites_port),
) -> BffService:
    return BffService(catalog, restaurants, reviews, favorites)


router = APIRouter(prefix="/bff", tags=["BFF (pantallas de la app)"])


@router.get("/home", response_model=HomeResponse, summary="Pantalla de inicio")
def home(service: BffService = Depends(get_bff_service)) -> HomeResponse:
    """Destacados, mejor calificados, recomendados (uno por categoría) y novedades, en una sola llamada."""
    return service.home()


@router.get(
    "/restaurants/{restaurant_id:int}",
    response_model=RestaurantScreen,
    summary="Pantalla de detalle de un restaurante",
    responses={
        401: {"model": ErrorResponse, "description": "Se envió un token inválido"},
        404: {"model": ErrorResponse, "description": "Restaurante no encontrado"},
    },
    # La sesión es opcional: sin token también responde (sin is_favorite).
    # FastAPI ya declara HTTPBearer; el requisito vacío {} lo marca como opcional.
    openapi_extra={"security": [{}]},
)
def restaurant_screen(
    restaurant_id: int,
    page: PageParams = Depends(),
    user: Optional[CurrentUser] = Depends(get_optional_user),
    service: BffService = Depends(get_bff_service),
) -> RestaurantScreen:
    """
    Restaurante, página de reseñas (`limit`/`offset`) y, si hay sesión, si es
    favorito, en una sola llamada. Si fallan las reseñas o los favoritos, la
    respuesta es 200 con `warnings`.
    """
    return service.restaurant_screen(restaurant_id, user, page)
