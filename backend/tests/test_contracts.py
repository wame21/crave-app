"""
Pruebas de los contratos: registro de implementaciones y fakes.

Las pruebas de los fakes fijan la semántica documentada en los docstrings
de `contracts/`, que las implementaciones reales también deben cumplir.
"""
import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from contracts import registry
from contracts.catalog import CatalogContract
from contracts.identity import IdentityContract
from contracts.registry import (
    ContractNotRegisteredError,
    get_catalog,
    get_identity,
    register_catalog,
    register_identity,
)
from core.errors import BusinessRuleError, ConflictError, NotFoundError
from tests.fakes import FakeCatalog, FakeIdentity


@pytest.fixture(autouse=True)
def clean_registry():
    registry.reset()
    yield
    registry.reset()


# ── Registro ─────────────────────────────────────────────────
def test_fakes_satisfy_the_contracts():
    assert isinstance(FakeCatalog(), CatalogContract)
    assert isinstance(FakeIdentity(), IdentityContract)


@pytest.mark.parametrize("get_contract", [get_catalog, get_identity])
def test_resolving_an_unregistered_contract_fails_clearly(get_contract):
    with pytest.raises(ContractNotRegisteredError):
        get_contract()


def test_register_and_resolve():
    catalog, identity = FakeCatalog(), FakeIdentity()

    register_catalog(catalog)
    register_identity(identity)

    assert get_catalog() is catalog
    assert get_identity() is identity


def test_registering_again_replaces_the_implementation():
    register_catalog(FakeCatalog())
    replacement = FakeCatalog()

    register_catalog(replacement)

    assert get_catalog() is replacement


@pytest.mark.parametrize(
    "register, impl",
    [(register_catalog, FakeIdentity()), (register_identity, FakeCatalog()), (register_catalog, object())],
)
def test_registering_something_that_does_not_implement_the_contract_fails(register, impl):
    with pytest.raises(TypeError):
        register(impl)


def test_contracts_are_injected_and_can_be_overridden_in_tests():
    app = FastAPI()

    @app.get("/exists/{restaurant_id}")
    def exists(restaurant_id: int, catalog: CatalogContract = Depends(get_catalog)):
        return {"exists": catalog.exists(restaurant_id)}

    catalog = FakeCatalog()
    catalog.add("Sushi Go", id_restaurant=5)
    app.dependency_overrides[get_catalog] = lambda: catalog

    client = TestClient(app)

    assert client.get("/exists/5").json() == {"exists": True}
    assert client.get("/exists/6").json() == {"exists": False}


# ── FakeCatalog ──────────────────────────────────────────────
@pytest.fixture
def catalog():
    fake = FakeCatalog()
    fake.add("Tacos", food_type="Tacos", overall_rating=4.5)  # id 1
    fake.add("Pizza", food_type="Pizza", overall_rating=3.0)  # id 2
    fake.add("Sushi", food_type="Sushi", overall_rating=4.5)  # id 3
    fake.add("Cerrado", food_type="Café", overall_rating=5.0, is_active=False)  # id 4
    return fake


def test_exists_counts_inactive_restaurants(catalog):
    assert catalog.exists(4)
    assert not catalog.exists(99)


def test_get_summaries_keeps_order_drops_duplicates_and_missing(catalog):
    summaries = catalog.get_summaries([3, 99, 1, 3, 4])

    assert [s.id_restaurant for s in summaries] == [3, 1, 4]


def test_get_summaries_of_nothing_is_empty(catalog):
    assert catalog.get_summaries([]) == []


def test_list_active_by_rating_breaks_ties_by_id(catalog):
    ids = [s.id_restaurant for s in catalog.list_active(limit=10, order_by="rating")]

    assert ids == [1, 3, 2]


def test_list_active_by_new_puts_most_recent_first(catalog):
    ids = [s.id_restaurant for s in catalog.list_active(limit=2, order_by="new")]

    assert ids == [3, 2]


@pytest.mark.parametrize("limit, order_by", [(0, "rating"), (101, "rating"), (5, "random")])
def test_list_active_rejects_bad_arguments(catalog, limit, order_by):
    with pytest.raises(ValueError):
        catalog.list_active(limit=limit, order_by=order_by)


def test_create_for_owner_creates_an_active_unrated_restaurant(catalog):
    new_id = catalog.create_for_owner(owner_id=10, name="La Nueva", food_type="Mariscos")

    [created] = catalog.get_summaries([new_id])
    assert (created.name, created.food_type) == ("La Nueva", "Mariscos")
    assert created.is_active and created.overall_rating == 0
    assert catalog.owners[new_id] == 10


def test_create_for_owner_twice_is_a_conflict(catalog):
    catalog.create_for_owner(owner_id=10, name="La Nueva", food_type="Mariscos")

    with pytest.raises(ConflictError):
        catalog.create_for_owner(owner_id=10, name="Otra", food_type="Tacos")


@pytest.mark.parametrize("name, food_type", [("  ", "Tacos"), ("La Nueva", "")])
def test_create_for_owner_requires_name_and_food_type(catalog, name, food_type):
    with pytest.raises(BusinessRuleError):
        catalog.create_for_owner(owner_id=10, name=name, food_type=food_type)


def test_delete_is_idempotent(catalog):
    catalog.delete(1)
    catalog.delete(1)

    assert not catalog.exists(1)


def test_set_rating_rounds_to_two_decimals(catalog):
    catalog.set_rating(2, 3.456)

    assert catalog.get_summaries([2])[0].overall_rating == 3.46


def test_set_rating_of_missing_restaurant_is_not_found(catalog):
    with pytest.raises(NotFoundError):
        catalog.set_rating(99, 4.0)


@pytest.mark.parametrize("value", [-0.1, 5.01, float("nan")])
def test_set_rating_rejects_out_of_range_values(catalog, value):
    with pytest.raises(ValueError):
        catalog.set_rating(2, value)


def test_calls_are_recorded(catalog):
    catalog.exists(1)
    catalog.set_rating(1, 4.0)

    assert catalog.calls == [("exists", (1,)), ("set_rating", (1, 4.0))]
    assert catalog.calls_to("set_rating") == [(1, 4.0)]


def test_fail_on_simulates_a_failure_and_still_records_the_call(catalog):
    catalog.fail_on("create_for_owner")

    with pytest.raises(RuntimeError):
        catalog.create_for_owner(owner_id=10, name="La Nueva", food_type="Mariscos")

    assert catalog.calls_to("create_for_owner") == [(10, "La Nueva", "Mariscos")]
    assert len(catalog.restaurants) == 4


def test_fail_on_accepts_a_specific_error(catalog):
    catalog.fail_on("exists", NotFoundError("Catálogo caído"))

    with pytest.raises(NotFoundError):
        catalog.exists(1)


def test_fail_on_unknown_method_is_a_typo(catalog):
    with pytest.raises(AttributeError):
        catalog.fail_on("crear")


# ── FakeIdentity ─────────────────────────────────────────────
def test_get_public_profiles_by_id():
    identity = FakeIdentity()
    ana = identity.add("Ana", photo_url="https://img/ana.png")
    beto = identity.add("Beto", id_user=7)

    profiles = identity.get_public_profiles([7, ana.id_user, 99, 7])

    assert profiles == {7: beto, ana.id_user: ana}
    assert identity.get_public_profiles([]) == {}


def test_public_profile_does_not_expose_private_data():
    profile = FakeIdentity().add("Ana")

    assert set(profile.model_dump()) == {"id_user", "profile_name", "photo_url"}
