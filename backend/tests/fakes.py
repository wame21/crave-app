"""
Implementaciones en memoria de los contratos, para las pruebas.

    catalog = FakeCatalog()
    tacos = catalog.add("Tacos Don Pepe", food_type="Tacos")
    app.dependency_overrides[get_catalog] = lambda: catalog

Cumplen las mismas precondiciones, postcondiciones y errores que los
contratos de `contracts/`, así que una prueba que pasa con el fake debería
pasar con la implementación real. Además:
- `calls` registra cada llamada al contrato como `(método, argumentos)`.
- `fail_on(método, error)` hace que ese método falle, para probar
  compensaciones y fallos parciales.
"""
from typing import Optional

from contracts.catalog import OrderBy, RestaurantSummary
from contracts.identity import PublicProfile
from core.errors import BusinessRuleError, ConflictError, NotFoundError


class _FakeService:
    def __init__(self):
        self.calls: list[tuple[str, tuple]] = []
        self.failures: dict[str, Exception] = {}

    def fail_on(self, method: str, error: Optional[Exception] = None) -> None:
        """Hace que `method` lance `error` (por defecto `RuntimeError`) en cada llamada."""
        if not callable(getattr(self, method, None)):
            raise AttributeError(f"{type(self).__name__} no tiene el método {method!r}")
        self.failures[method] = error or RuntimeError(f"Fallo simulado en {method}")

    def calls_to(self, method: str) -> list[tuple]:
        """Argumentos de cada llamada a `method`, en orden."""
        return [args for name, args in self.calls if name == method]

    def _record(self, method: str, *args) -> None:
        self.calls.append((method, args))
        if method in self.failures:
            raise self.failures[method]


class FakeCatalog(_FakeService):
    """`CatalogContract` en memoria."""

    def __init__(self):
        super().__init__()
        self.restaurants: dict[int, RestaurantSummary] = {}
        self.owners: dict[int, int] = {}  # id_restaurant → id del dueño
        self._next_id = 1

    def add(
        self,
        name: str = "Restaurante de prueba",
        *,
        id_restaurant: Optional[int] = None,
        owner_id: Optional[int] = None,
        **fields,
    ) -> RestaurantSummary:
        """
        Siembra un restaurante (no cuenta como llamada al contrato).
        `fields` acepta el resto de campos de `RestaurantSummary`.
        Los ids crecen con cada alta, como la fecha de alta real.
        """
        if id_restaurant is None:
            id_restaurant = self._next_id
        self._next_id = max(self._next_id, id_restaurant + 1)
        summary = RestaurantSummary(id_restaurant=id_restaurant, name=name, **fields)
        self.restaurants[id_restaurant] = summary
        if owner_id is not None:
            self.owners[id_restaurant] = owner_id
        return summary

    # ── CatalogContract ──────────────────────────────────────
    def exists(self, restaurant_id: int) -> bool:
        self._record("exists", restaurant_id)
        return restaurant_id in self.restaurants

    def get_summaries(self, ids: list[int]) -> list[RestaurantSummary]:
        self._record("get_summaries", list(ids))
        unique_ids = dict.fromkeys(ids)  # conserva el orden y quita repetidos
        return [self.restaurants[i] for i in unique_ids if i in self.restaurants]

    def list_active(self, limit: int, order_by: OrderBy) -> list[RestaurantSummary]:
        self._record("list_active", limit, order_by)
        if not 1 <= limit <= 100:
            raise ValueError(f"limit debe estar entre 1 y 100, no {limit}")
        active = [r for r in self.restaurants.values() if r.is_active]
        if order_by == "rating":
            active.sort(key=lambda r: (-r.overall_rating, r.id_restaurant))
        elif order_by == "new":
            active.sort(key=lambda r: r.id_restaurant, reverse=True)
        else:
            raise ValueError(f"order_by inválido: {order_by!r}")
        return active[:limit]

    def create_for_owner(self, owner_id: int, name: str, food_type: str) -> int:
        self._record("create_for_owner", owner_id, name, food_type)
        if not name.strip() or not food_type.strip():
            raise BusinessRuleError("El nombre y el tipo de comida son obligatorios")
        if owner_id in self.owners.values():
            raise ConflictError("El dueño ya tiene un restaurante")
        return self.add(name, food_type=food_type, owner_id=owner_id).id_restaurant

    def delete(self, restaurant_id: int) -> None:
        self._record("delete", restaurant_id)
        self.restaurants.pop(restaurant_id, None)
        self.owners.pop(restaurant_id, None)

    def set_rating(self, restaurant_id: int, value: float) -> None:
        self._record("set_rating", restaurant_id, value)
        if not 0 <= value <= 5:
            raise ValueError(f"La calificación debe estar entre 0 y 5, no {value}")
        if restaurant_id not in self.restaurants:
            raise NotFoundError("Restaurante no encontrado")
        self.restaurants[restaurant_id] = self.restaurants[restaurant_id].model_copy(
            update={"overall_rating": round(value, 2)}
        )


class FakeIdentity(_FakeService):
    """`IdentityContract` en memoria."""

    def __init__(self):
        super().__init__()
        self.profiles: dict[int, PublicProfile] = {}
        self._next_id = 1

    def add(
        self,
        profile_name: str = "Usuario de prueba",
        *,
        id_user: Optional[int] = None,
        photo_url: Optional[str] = None,
    ) -> PublicProfile:
        """Siembra un usuario (no cuenta como llamada al contrato)."""
        if id_user is None:
            id_user = self._next_id
        self._next_id = max(self._next_id, id_user + 1)
        profile = PublicProfile(id_user=id_user, profile_name=profile_name, photo_url=photo_url)
        self.profiles[id_user] = profile
        return profile

    # ── IdentityContract ─────────────────────────────────────
    def get_public_profiles(self, ids: list[int]) -> dict[int, PublicProfile]:
        self._record("get_public_profiles", list(ids))
        return {i: self.profiles[i] for i in dict.fromkeys(ids) if i in self.profiles}
