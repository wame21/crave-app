"""Pruebas unitarias del service de Reviews, con un repositorio en memoria, FakeCatalog y FakeIdentity."""
from datetime import datetime, timezone

import pytest

from core.errors import ConflictError, ForbiddenError, NotFoundError
from core.pagination import PageParams
from services.reviews.schemas import ReviewCreate
from services.reviews.service import ReviewsService, load_default_status
from tests.fakes import FakeCatalog, FakeIdentity

ANA, CARLOS = 1, 2


class FakeReviewRepository:
    """`ReviewStore` en memoria."""

    def __init__(self):
        self.rows: dict[int, dict] = {}
        self.commits = 0
        self._next_id = 1

    def list_approved_for_restaurant(self, restaurant_id, limit, offset):
        rows = self._newest_first(r for r in self.rows.values() if r["id_restaurant"] == restaurant_id and r["status"] == "Approved")
        return rows[offset : offset + limit], len(rows)

    def list_by_client(self, client_id, limit, offset):
        rows = self._newest_first(r for r in self.rows.values() if r["id_client"] == client_id)
        return rows[offset : offset + limit], len(rows)

    def get(self, review_id):
        return self.rows.get(review_id)

    def exists_for(self, client_id, restaurant_id):
        return any(r["id_client"] == client_id and r["id_restaurant"] == restaurant_id for r in self.rows.values())

    def create(self, *, client_id, restaurant_id, rating_food, rating_service, rating_atmosphere, comment, photo_gallery, status):
        row = {
            "id_review": self._next_id,
            "id_client": client_id,
            "id_restaurant": restaurant_id,
            "rating_food": rating_food,
            "rating_service": rating_service,
            "rating_atmosphere": rating_atmosphere,
            "comment": comment,
            "photo_gallery": photo_gallery,
            "status": status,
            "created_at": datetime.now(timezone.utc),
        }
        self.rows[self._next_id] = row
        self._next_id += 1
        return row

    def delete(self, review_id):
        self.rows.pop(review_id, None)

    def approved_average(self, restaurant_id):
        approved = [r for r in self.rows.values() if r["id_restaurant"] == restaurant_id and r["status"] == "Approved"]
        if not approved:
            return 0.0
        return round(sum((r["rating_food"] + r["rating_service"] + r["rating_atmosphere"]) / 3 for r in approved) / len(approved), 2)

    def commit(self):
        self.commits += 1

    @staticmethod
    def _newest_first(rows):
        return sorted(rows, key=lambda r: r["id_review"], reverse=True)


def _review(restaurant_id, food=5, service=5, atmosphere=5, **extra):
    return ReviewCreate(
        id_restaurant=restaurant_id, rating_food=food, rating_service=service, rating_atmosphere=atmosphere, **extra
    )


@pytest.fixture
def catalog():
    catalog = FakeCatalog()
    catalog.add("Taquería El Güero", id_restaurant=10, food_type="Tacos")
    catalog.add("Sushi Koi", id_restaurant=20, food_type="Sushi")
    return catalog


@pytest.fixture
def identity():
    identity = FakeIdentity()
    identity.add("Ana López", id_user=ANA, photo_url="https://img/ana.png")
    identity.add("Carlos Ramírez", id_user=CARLOS)
    return identity


@pytest.fixture
def repo():
    return FakeReviewRepository()


@pytest.fixture
def service(repo, catalog, identity):
    return ReviewsService(repo, catalog, identity)


# ── Crear ────────────────────────────────────────────────────
def test_al_crear_una_resena_se_publica_el_promedio_correcto(service, catalog):
    service.create(ANA, _review(10, 5, 5, 5))
    service.create(CARLOS, _review(10, 3, 3, 3))

    assert catalog.calls_to("set_rating") == [(10, 5.0), (10, 4.0)]
    assert catalog.get_summaries([10])[0].overall_rating == 4.0


def test_la_resena_nace_con_el_estado_configurado(repo, catalog, identity):
    service = ReviewsService(repo, catalog, identity, default_status="Pending")

    created = service.create(ANA, _review(10))

    assert created.status == "Pending"
    assert catalog.calls_to("set_rating") == [(10, 0.0)]  # las pendientes no cuentan


def test_la_resena_se_confirma_antes_de_avisar_a_catalog(service, repo, catalog):
    commits_al_avisar = []
    original = catalog.set_rating
    catalog.set_rating = lambda restaurant_id, value: (commits_al_avisar.append(repo.commits), original(restaurant_id, value))

    service.create(ANA, _review(10))

    assert commits_al_avisar == [1]


def test_no_se_puede_resenar_un_restaurante_inexistente(service, repo, catalog):
    with pytest.raises(NotFoundError):
        service.create(ANA, _review(99))

    assert repo.rows == {}
    assert catalog.calls_to("set_rating") == []


def test_un_cliente_solo_resena_una_vez_cada_restaurante(service):
    service.create(ANA, _review(10))

    with pytest.raises(ConflictError) as exc:
        service.create(ANA, _review(10, 1, 1, 1))
    assert exc.value.code == "review_exists"


def test_si_catalog_falla_la_resena_se_conserva_y_queda_en_el_log(service, repo, catalog, caplog):
    catalog.fail_on("set_rating")

    created = service.create(ANA, _review(10))

    assert created.id_review in repo.rows
    assert "No se pudo actualizar la calificación del restaurante 10" in caplog.text


# ── Borrar ───────────────────────────────────────────────────
def test_el_autor_borra_su_resena_y_se_recalcula_el_promedio(service, repo, catalog):
    mine = service.create(ANA, _review(10, 5, 5, 5))
    service.create(CARLOS, _review(10, 3, 3, 3))

    service.delete(mine.id_review, ANA)

    assert mine.id_review not in repo.rows
    assert catalog.calls_to("set_rating")[-1] == (10, 3.0)


def test_borrar_la_resena_de_otro_usuario_esta_prohibido(service, repo):
    ajena = service.create(CARLOS, _review(10))

    with pytest.raises(ForbiddenError):
        service.delete(ajena.id_review, ANA)

    assert ajena.id_review in repo.rows


def test_borrar_una_resena_inexistente(service):
    with pytest.raises(NotFoundError):
        service.delete(99, ANA)


# ── Listados ─────────────────────────────────────────────────
def test_resenas_de_un_restaurante_con_los_autores_en_una_sola_llamada(service, identity):
    service.create(ANA, _review(10))
    service.create(CARLOS, _review(10))
    service.create(CARLOS, _review(20))
    identity.calls.clear()

    page = service.list_for_restaurant(10, PageParams(limit=20, offset=0))

    assert [(r.client_name, r.client_photo) for r in page.items] == [
        ("Carlos Ramírez", None),
        ("Ana López", "https://img/ana.png"),
    ]
    assert page.total == 2
    assert len(identity.calls_to("get_public_profiles")) == 1


def test_un_autor_que_ya_no_existe_aparece_sin_nombre(service, identity):
    service.create(ANA, _review(10))
    identity.profiles.clear()

    [review] = service.list_for_restaurant(10, PageParams(limit=20, offset=0)).items

    assert review.client_name is None


def test_las_resenas_pendientes_no_se_muestran_en_el_restaurante(repo, catalog, identity):
    service = ReviewsService(repo, catalog, identity, default_status="Pending")
    service.create(ANA, _review(10))

    assert service.list_for_restaurant(10, PageParams(limit=20, offset=0)).total == 0


def test_resenas_de_un_restaurante_inexistente(service):
    with pytest.raises(NotFoundError):
        service.list_for_restaurant(99, PageParams(limit=20, offset=0))


def test_mis_resenas_con_el_nombre_del_restaurante_en_una_sola_llamada(service, catalog):
    service.create(ANA, _review(10))
    service.create(ANA, _review(20))
    service.create(CARLOS, _review(20))
    catalog.calls.clear()

    page = service.list_mine(ANA, PageParams(limit=1, offset=0))

    assert [r.restaurant_name for r in page.items] == ["Sushi Koi"]
    assert (page.total, page.limit) == (2, 1)
    assert len(catalog.calls_to("get_summaries")) == 1


# ── Configuración ────────────────────────────────────────────
@pytest.mark.parametrize("value, expected", [(None, "Approved"), ("Pending", "Pending"), ("  ", "Approved")])
def test_review_default_status(monkeypatch, value, expected):
    if value is None:
        monkeypatch.delenv("REVIEW_DEFAULT_STATUS", raising=False)
    else:
        monkeypatch.setenv("REVIEW_DEFAULT_STATUS", value)

    assert load_default_status() == expected


def test_un_review_default_status_invalido_impide_arrancar(monkeypatch):
    monkeypatch.setenv("REVIEW_DEFAULT_STATUS", "Rejected")

    with pytest.raises(RuntimeError, match="REVIEW_DEFAULT_STATUS"):
        load_default_status()
