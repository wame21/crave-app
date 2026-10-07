"""
Pruebas de CatalogProvider, la implementación real de CatalogContract, contra
PostgreSQL. Verifican las mismas pre y postcondiciones que tests/test_contracts.py
le exige a FakeCatalog, para que una prueba que pasa con el fake pase también
con la implementación real.
"""
import psycopg
import pytest

from config import DATABASE_URL
from core.errors import BusinessRuleError, ConflictError, NotFoundError
from services.catalog.provider import CatalogProvider

catalog = CatalogProvider()


def _id_of(name: str) -> int:
    with psycopg.connect(DATABASE_URL) as conn:
        return conn.execute("SELECT id_restaurant FROM catalog.restaurants WHERE name = %s", (name,)).fetchone()[0]


def test_exists():
    assert catalog.exists(_id_of("Sushi Koi"))
    assert not catalog.exists(999_999_999)


def test_get_summaries_conserva_el_orden_quita_repetidos_y_omite_inexistentes():
    sushi, tacos = _id_of("Sushi Koi"), _id_of("Taquería El Güero")

    summaries = catalog.get_summaries([sushi, 999_999_999, tacos, sushi])

    assert [s.id_restaurant for s in summaries] == [sushi, tacos]
    assert summaries[0].name == "Sushi Koi" and summaries[0].food_type == "Sushi"
    assert catalog.get_summaries([]) == []


def test_list_active_por_rating():
    restaurants = catalog.list_active(limit=100, order_by="rating")

    keys = [(-r.overall_rating, r.id_restaurant) for r in restaurants]
    assert keys == sorted(keys)
    assert all(r.is_active for r in restaurants)
    assert len(catalog.list_active(limit=3, order_by="rating")) == 3


def test_list_active_por_fecha_de_alta(new_owner_id):
    older = catalog.create_for_owner(new_owner_id, "Prueba antigua", "Pizza")
    newer = catalog.create_for_owner(new_owner_id + 1, "Prueba reciente", "Pizza")

    assert [r.id_restaurant for r in catalog.list_active(limit=2, order_by="new")] == [newer, older]


@pytest.mark.parametrize("limit, order_by", [(0, "rating"), (101, "rating"), (10, "nombre")])
def test_list_active_rechaza_precondiciones_incumplidas(limit, order_by):
    with pytest.raises(ValueError):
        catalog.list_active(limit=limit, order_by=order_by)


def test_create_for_owner(new_owner_id):
    restaurant_id = catalog.create_for_owner(new_owner_id, "  La Nueva  ", "Mariscos")

    [created] = catalog.get_summaries([restaurant_id])
    assert (created.name, created.food_type, created.overall_rating, created.is_active) == (
        "La Nueva", "Mariscos", 0.0, True,
    )


def test_un_dueno_solo_puede_tener_un_restaurante(new_owner_id):
    catalog.create_for_owner(new_owner_id, "Primero", "Tacos")

    with pytest.raises(ConflictError):
        catalog.create_for_owner(new_owner_id, "Segundo", "Tacos")


@pytest.mark.parametrize("name, food_type", [("", "Tacos"), ("Nombre", "  ")])
def test_create_for_owner_exige_nombre_y_tipo(new_owner_id, name, food_type):
    with pytest.raises(BusinessRuleError):
        catalog.create_for_owner(new_owner_id, name, food_type)


def test_create_for_owner_con_una_categoria_inexistente(new_owner_id):
    with pytest.raises(BusinessRuleError) as exc:
        catalog.create_for_owner(new_owner_id, "Thai House", "Tailandesa")

    assert exc.value.code == "unknown_category"


def test_delete_es_idempotente(new_owner_id):
    restaurant_id = catalog.create_for_owner(new_owner_id, "Temporal", "Café")

    catalog.delete(restaurant_id)
    catalog.delete(restaurant_id)

    assert not catalog.exists(restaurant_id)


def test_set_rating_redondea_a_dos_decimales(new_owner_id):
    restaurant_id = catalog.create_for_owner(new_owner_id, "Con rating", "China")

    catalog.set_rating(restaurant_id, 3.456)

    assert catalog.get_summaries([restaurant_id])[0].overall_rating == 3.46


def test_set_rating_de_un_restaurante_inexistente():
    with pytest.raises(NotFoundError):
        catalog.set_rating(999_999_999, 4.0)


@pytest.mark.parametrize("value", [-0.1, 5.01])
def test_set_rating_fuera_de_rango(value):
    with pytest.raises(ValueError):
        catalog.set_rating(1, value)
