"""Pruebas unitarias de la composición del BFF, con FakeCatalog y fakes de los puertos."""
from datetime import datetime, timezone

import pytest

from bff.service import BffService
from core.errors import NotFoundError
from core.pagination import Page, PageParams
from core.security import CurrentUser
from services.catalog.schemas import RestaurantDetail
from services.reviews.schemas import ReviewResponse
from tests.fakes import FakeCatalog

ANA = CurrentUser(id=1, email="ana@example.com", role="Client")
PAGE = PageParams(limit=20, offset=0)


class FakeRestaurants:
    def __init__(self, *details):
        self.details = {d.id_restaurant: d for d in details}

    def get_detail(self, restaurant_id):
        if restaurant_id not in self.details:
            raise NotFoundError("Restaurante no encontrado")
        return self.details[restaurant_id]


class FakeReviews:
    def __init__(self, reviews=(), error=None):
        self.reviews = list(reviews)
        self.error = error

    def list_for_restaurant(self, restaurant_id, page):
        if self.error:
            raise self.error
        items = [r for r in self.reviews if r.id_restaurant == restaurant_id]
        return Page.create(items[page.offset : page.offset + page.limit], total=len(items), params=page)


class FakeFavorites:
    def __init__(self, favorites=(), error=None):
        self.favorites = set(favorites)
        self.error = error
        self.calls = []

    def is_favorite(self, client_id, restaurant_id):
        self.calls.append((client_id, restaurant_id))
        if self.error:
            raise self.error
        return (client_id, restaurant_id) in self.favorites


def _review(review_id, restaurant_id, ratings=(5, 4, 3), author="Ana López"):
    return ReviewResponse(
        id_review=review_id,
        id_client=1,
        id_restaurant=restaurant_id,
        rating_food=ratings[0],
        rating_service=ratings[1],
        rating_atmosphere=ratings[2],
        comment="Rico",
        status="Approved",
        created_at=datetime(2026, 10, 1, tzinfo=timezone.utc),
        client_name=author,
    )


@pytest.fixture
def catalog():
    """12 restaurantes: el id crece con la fecha de alta, el rating no sigue ese orden."""
    catalog = FakeCatalog()
    ratings = [3.0, 4.9, 2.5, 4.1, 5.0, 3.8, 4.5, 1.0, 4.7, 3.3, 2.0, 4.0]
    types = ["Tacos", "Sushi", "Tacos", "Pizza", "Sushi", "Café", "Tacos", "China", "Pizza", "Café", "Mariscos", "Italiana"]
    for i, (rating, food_type) in enumerate(zip(ratings, types), start=1):
        catalog.add(f"R{i}", id_restaurant=i, food_type=food_type, overall_rating=rating)
    return catalog


def _service(catalog, restaurants=None, reviews=None, favorites=None):
    return BffService(catalog, restaurants or FakeRestaurants(), reviews or FakeReviews(), favorites or FakeFavorites())


# ── Home ─────────────────────────────────────────────────────
def test_newest_sale_ordenado_por_fecha_y_featured_por_rating(catalog):
    home = _service(catalog).home()

    assert [r.id_restaurant for r in home.newest] == [12, 11, 10, 9, 8, 7, 6, 5, 4, 3]
    assert [r.overall_rating for r in home.featured] == [5.0, 4.9, 4.7, 4.5, 4.1]


def test_top_rated_y_recommended(catalog):
    home = _service(catalog).home()

    assert len(home.top_rated) == 10
    assert [r.overall_rating for r in home.top_rated] == sorted((r.overall_rating for r in home.top_rated), reverse=True)
    # El mejor de cada categoría, sin repetir categorías.
    assert [(r.food_type, r.overall_rating) for r in home.recommended] == [
        ("Sushi", 5.0), ("Pizza", 4.7), ("Tacos", 4.5), ("Italiana", 4.0), ("Café", 3.8), ("Mariscos", 2.0), ("China", 1.0),
    ]
    assert home.warnings == []


def test_home_usa_list_active_del_contrato(catalog):
    _service(catalog).home()

    assert catalog.calls_to("list_active") == [(100, "rating"), (10, "new")]


def test_si_fallan_las_novedades_el_home_responde_con_aviso(catalog):
    original = catalog.list_active

    def list_active(limit, order_by):
        if order_by == "new":
            raise ConnectionError("Catalog no responde")
        return original(limit, order_by)

    catalog.list_active = list_active

    home = _service(catalog).home()

    assert home.newest == []
    assert len(home.featured) == 5
    assert home.warnings == ["No se pudieron cargar las novedades"]


# ── Detalle ──────────────────────────────────────────────────
@pytest.fixture
def restaurants():
    return FakeRestaurants(RestaurantDetail(id_restaurant=7, name="Taquería", food_type="Tacos", phone="55", overall_rating=4.5))


def test_el_detalle_compone_restaurante_resenas_y_favorito(catalog, restaurants):
    reviews = FakeReviews([_review(1, 7, (5, 4, 3)), _review(2, 7, (5, 5, 5), author=None), _review(3, 8)])
    favorites = FakeFavorites({(ANA.id, 7)})

    screen = _service(catalog, restaurants, reviews, favorites).restaurant_screen(7, ANA, PAGE)

    assert (screen.restaurant.name, screen.restaurant.phone) == ("Taquería", "55")
    assert screen.reviews.total == 2
    assert [(r.author_name, r.rating_average) for r in screen.reviews.items] == [("Ana López", 4.0), (None, 5.0)]
    assert screen.is_favorite is True
    assert screen.warnings == []


def test_sin_token_no_se_consulta_el_favorito(catalog, restaurants):
    favorites = FakeFavorites()

    screen = _service(catalog, restaurants, favorites=favorites).restaurant_screen(7, None, PAGE)

    assert screen.is_favorite is None
    assert favorites.calls == []


def test_si_falla_el_servicio_de_resenas_hay_aviso_en_lugar_de_error(catalog, restaurants):
    screen = _service(catalog, restaurants, reviews=FakeReviews(error=ConnectionError("caído"))).restaurant_screen(7, ANA, PAGE)

    assert screen.reviews is None
    assert screen.warnings == ["No se pudieron cargar las reseñas"]
    assert screen.restaurant.name == "Taquería"


def test_si_falla_el_servicio_de_favoritos_hay_aviso(catalog, restaurants):
    screen = _service(catalog, restaurants, favorites=FakeFavorites(error=TimeoutError())).restaurant_screen(7, ANA, PAGE)

    assert screen.is_favorite is None
    assert screen.warnings == ["No se pudo consultar si el restaurante es favorito"]


def test_restaurante_inexistente(catalog, restaurants):
    with pytest.raises(NotFoundError):
        _service(catalog, restaurants).restaurant_screen(99, ANA, PAGE)
