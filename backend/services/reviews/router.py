"""
Rutas HTTP del servicio Reviews: /reviews.
"""
from typing import Any

from fastapi import APIRouter, Depends, Response, status

from contracts.catalog import CatalogContract
from contracts.identity import IdentityContract
from contracts.registry import get_catalog, get_identity
from core.errors import ErrorResponse
from core.pagination import Page, PageParams
from core.security import CurrentUser, get_current_user, require_role
from database import DbConn
from services.reviews.repository import ReviewRepository
from services.reviews.schemas import ReviewCreate, ReviewResponse
from services.reviews.service import ReviewsService, load_default_status

# Estado inicial de las reseñas nuevas (variable REVIEW_DEFAULT_STATUS).
DEFAULT_STATUS = load_default_status()

_ERROR_DESCRIPTIONS = {
    401: "Falta el token o es inválido",
    403: "Requiere el rol Client, o la reseña es de otro usuario",
    404: "Restaurante o reseña no encontrados",
    409: "El cliente ya reseñó este restaurante",
}


def _errors(*codes: int) -> dict[int | str, dict[str, Any]]:
    return {code: {"model": ErrorResponse, "description": _ERROR_DESCRIPTIONS[code]} for code in codes}


def get_reviews_service(
    db: DbConn,
    catalog: CatalogContract = Depends(get_catalog),
    identity: IdentityContract = Depends(get_identity),
) -> ReviewsService:
    return ReviewsService(ReviewRepository(db), catalog, identity, default_status=DEFAULT_STATUS)


router = APIRouter(prefix="/reviews", tags=["Reseñas"])


@router.get(
    "/restaurant/{restaurant_id}",
    response_model=Page[ReviewResponse],
    summary="Reseñas aprobadas de un restaurante",
    responses=_errors(404),
)
def get_restaurant_reviews(
    restaurant_id: int,
    page: PageParams = Depends(),
    service: ReviewsService = Depends(get_reviews_service),
) -> Page[ReviewResponse]:
    """De la más reciente a la más antigua, con el nombre y la foto de cada autor."""
    return service.list_for_restaurant(restaurant_id, page)


@router.get("/me", response_model=Page[ReviewResponse], summary="Mis reseñas", responses=_errors(401))
def get_my_reviews(
    page: PageParams = Depends(),
    user: CurrentUser = Depends(get_current_user),
    service: ReviewsService = Depends(get_reviews_service),
) -> Page[ReviewResponse]:
    """Todas mis reseñas, también las pendientes de moderación, con el nombre del restaurante."""
    return service.list_mine(user.id, page)


@router.post(
    "",
    response_model=ReviewResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Publicar una reseña (Client)",
    responses=_errors(401, 403, 404, 409),
)
def create_review(
    body: ReviewCreate,
    user: CurrentUser = Depends(require_role("Client")),
    service: ReviewsService = Depends(get_reviews_service),
) -> ReviewResponse:
    """
    Publica una reseña y actualiza la calificación del restaurante en Catalog.

    El estado inicial lo fija `REVIEW_DEFAULT_STATUS`: `Approved` (por defecto)
    o `Pending` si las reseñas pasan por moderación. Solo las aprobadas se
    muestran en el restaurante y cuentan para su calificación. Cada cliente
    puede reseñar un restaurante una sola vez.
    """
    return service.create(user.id, body)


@router.delete(
    "/{review_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    summary="Eliminar una reseña propia",
    responses=_errors(401, 403, 404),
)
def delete_review(
    review_id: int,
    user: CurrentUser = Depends(get_current_user),
    service: ReviewsService = Depends(get_reviews_service),
) -> Response:
    """Solo el autor puede eliminarla; la calificación del restaurante se recalcula."""
    service.delete(review_id, user.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
