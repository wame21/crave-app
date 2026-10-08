"""
Rutas HTTP del servicio Catalog: /restaurants.

La pantalla de inicio (antes `GET /restaurants/home`) ya no vive aquí: la
compone el BFF a partir de `CatalogContract`.
"""
from typing import Any, Optional

from fastapi import APIRouter, Depends, Query

from contracts.catalog import OrderBy, RestaurantSummary
from contracts.registry import register_catalog
from core.errors import ErrorResponse
from core.pagination import Page, PageParams
from core.security import CurrentUser, require_role
from database import DbConn
from services.catalog.provider import CatalogProvider
from services.catalog.repository import RestaurantRepository
from services.catalog.schemas import CategoriesResponse, RestaurantDetail, RestaurantUpdate
from services.catalog.service import CatalogService

_ERROR_DESCRIPTIONS = {
    401: "Falta el token o es inválido",
    403: "Requiere el rol Owner, o el restaurante es de otro dueño",
    404: "Restaurante no encontrado",
}


def _errors(*codes: int) -> dict[int | str, dict[str, Any]]:
    return {code: {"model": ErrorResponse, "description": _ERROR_DESCRIPTIONS[code]} for code in codes}


def get_catalog_service(db: DbConn) -> CatalogService:
    return CatalogService(RestaurantRepository(db))


router = APIRouter(prefix="/restaurants", tags=["Restaurantes"])


@router.get("", response_model=Page[RestaurantSummary], summary="Listar y buscar restaurantes")
def list_restaurants(
    q: Optional[str] = Query(None, max_length=100, description="Texto a buscar en el nombre o el tipo de comida"),
    category: Optional[str] = Query(None, description="Categoría exacta (ver /restaurants/categories)"),
    sort: OrderBy = Query("rating", description="`rating`: mejor calificados primero; `new`: más recientes primero"),
    page: PageParams = Depends(),
    service: CatalogService = Depends(get_catalog_service),
) -> Page[RestaurantSummary]:
    """Restaurantes activos. `total` es el número de resultados del filtro, no el tamaño de la página."""
    return service.search(q=q, category=category, sort=sort, page=page)


@router.get("/categories", response_model=CategoriesResponse, summary="Listar categorías de comida")
def get_categories(service: CatalogService = Depends(get_catalog_service)) -> CategoriesResponse:
    return service.categories()


@router.get("/me", response_model=RestaurantDetail, summary="Mi restaurante (Owner)", responses=_errors(401, 403, 404))
def get_my_restaurant(
    user: CurrentUser = Depends(require_role("Owner")),
    service: CatalogService = Depends(get_catalog_service),
) -> RestaurantDetail:
    return service.get_owned_by(user.id)


@router.get("/{restaurant_id:int}", response_model=RestaurantDetail, summary="Detalle de un restaurante", responses=_errors(404))
def get_restaurant(restaurant_id: int, service: CatalogService = Depends(get_catalog_service)) -> RestaurantDetail:
    return service.get(restaurant_id)


@router.put(
    "/{restaurant_id:int}",
    response_model=RestaurantDetail,
    summary="Editar mi restaurante (Owner)",
    responses=_errors(401, 403, 404),
)
def update_restaurant(
    restaurant_id: int,
    body: RestaurantUpdate,
    user: CurrentUser = Depends(require_role("Owner")),
    service: CatalogService = Depends(get_catalog_service),
) -> RestaurantDetail:
    """Solo el dueño del restaurante puede editarlo; solo se cambian los campos enviados."""
    return service.update(restaurant_id, user.id, body)


register_catalog(CatalogProvider())
