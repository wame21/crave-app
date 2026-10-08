"""
Rutas HTTP del servicio Favorites: /favorites (del usuario autenticado).
"""
from typing import Any

from fastapi import APIRouter, Depends, Response, status

from contracts.catalog import CatalogContract
from contracts.registry import get_catalog
from core.errors import ErrorResponse
from core.pagination import Page, PageParams
from core.security import CurrentUser, get_current_user
from database import DbConn
from services.favorites.repository import FavoriteRepository
from services.favorites.schemas import FavoriteResponse, FavoriteStatus
from services.favorites.service import FavoritesService

_ERROR_DESCRIPTIONS = {
    401: "Falta el token o es inválido",
    404: "El restaurante no existe o no era favorito",
    409: "El restaurante ya está en favoritos",
}


def _errors(*codes: int) -> dict[int | str, dict[str, Any]]:
    return {code: {"model": ErrorResponse, "description": _ERROR_DESCRIPTIONS[code]} for code in codes}


def get_favorites_service(db: DbConn, catalog: CatalogContract = Depends(get_catalog)) -> FavoritesService:
    return FavoritesService(FavoriteRepository(db), catalog)


router = APIRouter(prefix="/favorites", tags=["Favoritos"])


@router.get("", response_model=Page[FavoriteResponse], summary="Mis restaurantes favoritos", responses=_errors(401))
def get_my_favorites(
    page: PageParams = Depends(),
    user: CurrentUser = Depends(get_current_user),
    service: FavoritesService = Depends(get_favorites_service),
) -> Page[FavoriteResponse]:
    """Del más reciente al más antiguo. Se omiten los restaurantes que ya no existen."""
    return service.list_mine(user.id, page)


@router.get(
    "/{restaurant_id:int}",
    response_model=FavoriteStatus,
    summary="¿Es favorito este restaurante?",
    responses=_errors(401, 404),
)
def get_favorite_status(
    restaurant_id: int,
    user: CurrentUser = Depends(get_current_user),
    service: FavoritesService = Depends(get_favorites_service),
) -> FavoriteStatus:
    """Para pintar el corazón del detalle sin descargar la lista completa."""
    return service.status(user.id, restaurant_id)


@router.post(
    "/{restaurant_id:int}",
    response_model=FavoriteResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Agregar a favoritos",
    responses=_errors(401, 404, 409),
)
def add_favorite(
    restaurant_id: int,
    user: CurrentUser = Depends(get_current_user),
    service: FavoritesService = Depends(get_favorites_service),
) -> FavoriteResponse:
    return service.add(user.id, restaurant_id)


@router.delete(
    "/{restaurant_id:int}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    summary="Quitar de favoritos",
    responses=_errors(401, 404),
)
def remove_favorite(
    restaurant_id: int,
    user: CurrentUser = Depends(get_current_user),
    service: FavoritesService = Depends(get_favorites_service),
) -> Response:
    service.remove(user.id, restaurant_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
