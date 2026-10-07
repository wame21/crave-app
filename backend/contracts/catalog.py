"""
Contrato del servicio Catalog: lo que los demás servicios pueden pedirle
sobre restaurantes. Catalog es el único dueño de esos datos; nadie más
lee ni escribe el esquema `catalog`.

Reglas comunes a todos los métodos:
- Son síncronos.
- Cada llamada es atómica y se confirma por sí misma: no participa en la
  transacción del servicio que la hace. Por eso el registro de dueño
  necesita una compensación (`delete`) si falla después de crear.
- Un argumento que incumple una precondición lanza `ValueError` (es un
  error de programación del llamador). Las situaciones de negocio lanzan
  las excepciones de `core.errors` que indica cada método.
"""
from typing import Literal, Optional, Protocol, runtime_checkable

from pydantic import BaseModel, ConfigDict, Field

OrderBy = Literal["rating", "new"]


class RestaurantSummary(BaseModel):
    """Vista resumida de un restaurante, la que se usa en listas y tarjetas."""

    model_config = ConfigDict(frozen=True)

    id_restaurant: int
    name: str
    food_type: Optional[str] = None
    description: Optional[str] = None
    price_range: Optional[str] = None
    address: Optional[str] = None
    overall_rating: float = Field(default=0.0, ge=0, le=5)
    is_active: bool = True


@runtime_checkable
class CatalogContract(Protocol):
    def exists(self, restaurant_id: int) -> bool:
        """
        Indica si existe un restaurante.

        Precondiciones: ninguna.
        Postcondiciones: devuelve True si existe un restaurante con ese id,
            esté activo o no; False en otro caso. No modifica nada.
        Errores: ninguno.
        """

    def get_summaries(self, ids: list[int]) -> list[RestaurantSummary]:
        """
        Resúmenes de varios restaurantes en una sola llamada (evita N+1).

        Precondiciones: ninguna; `ids` puede estar vacía o tener repetidos.
        Postcondiciones: un resumen por cada id que existe (activo o no),
            sin duplicados y en el orden en que aparece por primera vez en
            `ids`. Los ids inexistentes se omiten. Con `ids` vacía devuelve [].
        Errores: ninguno.
        """

    def list_active(self, limit: int, order_by: OrderBy) -> list[RestaurantSummary]:
        """
        Restaurantes activos para portadas y recomendaciones.

        Precondiciones: 1 <= limit <= 100; `order_by` es "rating" o "new".
        Postcondiciones: hasta `limit` restaurantes con `is_active=True`,
            ordenados según `order_by`:
            - "rating": `overall_rating` descendente; a igual rating,
              `id_restaurant` ascendente.
            - "new": fecha de alta descendente (los más recientes primero).
        Errores: ValueError si se incumple una precondición.
        """

    def create_for_owner(self, owner_id: int, name: str, food_type: str) -> int:
        """
        Crea el restaurante de un dueño recién registrado (paso 2 de la saga
        de registro de dueño en Identity).

        Precondiciones: `owner_id` es el id de un usuario con rol Owner (Catalog
            no lo verifica); `name` y `food_type` no están vacíos.
        Postcondiciones: existe un restaurante nuevo, activo, con
            `overall_rating` 0 e `id_owner = owner_id`, y se devuelve su
            `id_restaurant`. Queda confirmado al volver: si un paso posterior
            de la saga falla, el llamador compensa con `delete`.
        Errores:
            BusinessRuleError si `name` o `food_type` están vacíos.
            ConflictError si el dueño ya tiene un restaurante.
        """

    def delete(self, restaurant_id: int) -> None:
        """
        Borra un restaurante. Es la compensación de `create_for_owner`.

        Precondiciones: ninguna.
        Postcondiciones: no existe ningún restaurante con ese id. Es
            idempotente: borrar uno inexistente no hace nada, así que la
            compensación se puede reintentar sin riesgo.
        Errores: ninguno.
        """

    def set_rating(self, restaurant_id: int, value: float) -> None:
        """
        Fija la calificación global de un restaurante. Reviews la calcula
        a partir de sus reseñas y la publica aquí.

        Precondiciones: 0 <= value <= 5 (0 significa "sin reseñas").
        Postcondiciones: `overall_rating` del restaurante es `value`
            redondeado a 2 decimales.
        Errores:
            ValueError si `value` está fuera de rango.
            NotFoundError si el restaurante no existe.
        """
