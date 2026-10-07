"""
Reglas de negocio del servicio Reviews.

Estado inicial de las reseñas: lo fija la variable `REVIEW_DEFAULT_STATUS`
(`Approved` por defecto, o `Pending` si se quiere moderación). Solo las
reseñas aprobadas se muestran en el restaurante y cuentan para su calificación.
"""
import logging
import os
from typing import Any, Optional, Protocol, get_args

from contracts.catalog import CatalogContract
from contracts.identity import IdentityContract
from core.errors import ConflictError, ForbiddenError, NotFoundError
from core.pagination import Page, PageParams
from services.reviews.schemas import ReviewCreate, ReviewResponse, ReviewStatus

logger = logging.getLogger(__name__)

INITIAL_STATUSES = ("Approved", "Pending")
assert set(INITIAL_STATUSES) <= set(get_args(ReviewStatus))


def load_default_status() -> str:
    """Lee `REVIEW_DEFAULT_STATUS`; si tiene un valor inválido, la app no arranca."""
    value = os.getenv("REVIEW_DEFAULT_STATUS", "Approved").strip() or "Approved"
    if value not in INITIAL_STATUSES:
        raise RuntimeError(f"REVIEW_DEFAULT_STATUS debe ser uno de {INITIAL_STATUSES}, no {value!r}")
    return value


class ReviewStore(Protocol):
    """Lo que el service necesita del repositorio (`ReviewRepository` o un fake)."""

    def list_approved_for_restaurant(self, restaurant_id: int, limit: int, offset: int) -> tuple[list[dict[str, Any]], int]: ...
    def list_by_client(self, client_id: int, limit: int, offset: int) -> tuple[list[dict[str, Any]], int]: ...
    def get(self, review_id: int) -> Optional[dict[str, Any]]: ...
    def exists_for(self, client_id: int, restaurant_id: int) -> bool: ...
    def create(self, **fields: Any) -> dict[str, Any]: ...
    def delete(self, review_id: int) -> None: ...
    def approved_average(self, restaurant_id: int) -> float: ...
    def commit(self) -> None: ...


class ReviewsService:
    def __init__(
        self,
        reviews: ReviewStore,
        catalog: CatalogContract,
        identity: IdentityContract,
        *,
        default_status: str = "Approved",
    ):
        self._reviews = reviews
        self._catalog = catalog
        self._identity = identity
        self._default_status = default_status

    def list_for_restaurant(self, restaurant_id: int, page: PageParams) -> Page[ReviewResponse]:
        """Reseñas aprobadas, con nombre y foto de cada autor (una sola llamada a Identity)."""
        if not self._catalog.exists(restaurant_id):
            raise NotFoundError("Restaurante no encontrado")
        rows, total = self._reviews.list_approved_for_restaurant(restaurant_id, page.limit, page.offset)
        profiles = self._identity.get_public_profiles(list({row["id_client"] for row in rows}))
        items = []
        for row in rows:
            profile = profiles.get(row["id_client"])
            items.append(ReviewResponse.model_validate({
                **row,
                "client_name": profile.profile_name if profile else None,
                "client_photo": profile.photo_url if profile else None,
            }))
        return Page.create(items, total=total, params=page)

    def list_mine(self, client_id: int, page: PageParams) -> Page[ReviewResponse]:
        """Reseñas del cliente en cualquier estado, con el nombre de cada restaurante (una llamada a Catalog)."""
        rows, total = self._reviews.list_by_client(client_id, page.limit, page.offset)
        names = {
            summary.id_restaurant: summary.name
            for summary in self._catalog.get_summaries([row["id_restaurant"] for row in rows])
        }
        items = [
            ReviewResponse.model_validate({**row, "restaurant_name": names.get(row["id_restaurant"])})
            for row in rows
        ]
        return Page.create(items, total=total, params=page)

    def create(self, client_id: int, data: ReviewCreate) -> ReviewResponse:
        """
        Publica una reseña con el estado inicial configurado y actualiza la
        calificación del restaurante. Lanza `NotFoundError` si el restaurante
        no existe y `ConflictError` si el cliente ya lo reseñó.
        """
        if not self._catalog.exists(data.id_restaurant):
            raise NotFoundError("Restaurante no encontrado")
        if self._reviews.exists_for(client_id, data.id_restaurant):
            raise ConflictError("Ya publicaste una reseña de este restaurante", code="review_exists")
        row = self._reviews.create(
            client_id=client_id,
            restaurant_id=data.id_restaurant,
            rating_food=data.rating_food,
            rating_service=data.rating_service,
            rating_atmosphere=data.rating_atmosphere,
            comment=data.comment,
            photo_gallery=data.photo_gallery,
            status=self._default_status,
        )
        self._reviews.commit()
        self._publish_rating(data.id_restaurant)
        return ReviewResponse.model_validate(row)

    def delete(self, review_id: int, client_id: int) -> None:
        """Solo el autor puede borrar su reseña (si no, `ForbiddenError`)."""
        review = self._reviews.get(review_id)
        if review is None:
            raise NotFoundError("Reseña no encontrada")
        if review["id_client"] != client_id:
            raise ForbiddenError("No puedes eliminar la reseña de otro usuario")
        self._reviews.delete(review_id)
        self._reviews.commit()
        self._publish_rating(review["id_restaurant"])

    def _publish_rating(self, restaurant_id: int) -> None:
        """
        Envía a Catalog el promedio de las reseñas aprobadas. La reseña ya está
        confirmada: si Catalog falla, se registra y la calificación se corrige
        con la siguiente reseña de ese restaurante.
        """
        average = self._reviews.approved_average(restaurant_id)
        try:
            self._catalog.set_rating(restaurant_id, average)
        except Exception:
            logger.exception("No se pudo actualizar la calificación del restaurante %s", restaurant_id)
