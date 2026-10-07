"""Pruebas unitarias del service de Identity, con un repositorio en memoria y FakeCatalog."""
import bcrypt
import pytest
from pydantic import ValidationError

from core.errors import BusinessRuleError, ConflictError, NotFoundError, UnauthorizedError
from core.security import decode_access_token
from services.identity import service as service_module
from services.identity.schemas import RegisterClientRequest, RegisterOwnerRequest, UpdateProfileRequest
from services.identity.service import INVALID_CREDENTIALS, IdentityService
from tests.fakes import FakeCatalog


class FakeUserRepository:
    """`UserStore` en memoria."""

    def __init__(self):
        self.users: dict[int, dict] = {}
        self.commits = 0
        self.fail_on_delete = False
        self._next_id = 1

    def get_by_email(self, email):
        return next((dict(u) for u in self.users.values() if u["email"] == email), None)

    def get_by_id(self, user_id):
        user = self.users.get(user_id)
        return _without_password(user) if user else None

    def create(self, *, profile_name, email, password_hash, role):
        if self.get_by_email(email):
            raise ConflictError("Este correo ya está registrado", code="email_taken")
        user = {
            "id_user": self._next_id,
            "profile_name": profile_name,
            "email": email,
            "password_hash": password_hash,
            "role": role,
            "photo_url": None,
            "created_at": None,
        }
        self.users[self._next_id] = user
        self._next_id += 1
        return _without_password(user)

    def update(self, user_id, fields):
        if user_id not in self.users:
            return None
        self.users[user_id].update(fields)
        return _without_password(self.users[user_id])

    def delete(self, user_id):
        if self.fail_on_delete:
            raise RuntimeError("BD caída")
        self.users.pop(user_id, None)

    def commit(self):
        self.commits += 1


def _without_password(user):
    return {key: value for key, value in user.items() if key != "password_hash"}


def _client_data(**overrides):
    data = {"profile_name": "Ana", "email": "ana@example.com", "password": "123456", "confirm_password": "123456"}
    return RegisterClientRequest(**{**data, **overrides})


def _owner_data(**overrides):
    data = {
        "profile_name": "María",
        "email": "maria@example.com",
        "password": "123456",
        "confirm_password": "123456",
        "restaurant_name": "Taquería El Güero",
        "food_type": "Tacos",
    }
    return RegisterOwnerRequest(**{**data, **overrides})


@pytest.fixture(autouse=True)
def fast_bcrypt(monkeypatch):
    """bcrypt con el costo mínimo: las pruebas no miden la seguridad del hash."""
    monkeypatch.setattr(
        service_module,
        "hash_password",
        lambda plain: bcrypt.hashpw(plain.encode(), bcrypt.gensalt(rounds=4)).decode(),
    )
    service_module._dummy_hash.cache_clear()


@pytest.fixture
def users():
    return FakeUserRepository()


@pytest.fixture
def service(users):
    return IdentityService(users)


@pytest.fixture
def catalog():
    return FakeCatalog()


# ── Registro de cliente ──────────────────────────────────────
def test_registrar_cliente_guarda_el_hash_y_devuelve_su_token(service, users):
    token = service.register_client(_client_data())

    user = decode_access_token(token.access_token)
    assert (user.email, user.role) == ("ana@example.com", "Client")
    assert (token.user_id, token.role, token.profile_name) == (user.id, "Client", "Ana")
    stored = users.users[token.user_id]["password_hash"]
    assert stored != "123456" and bcrypt.checkpw(b"123456", stored.encode())


def test_registrar_un_correo_repetido_lanza_conflicto(service):
    service.register_client(_client_data())

    with pytest.raises(ConflictError) as exc:
        service.register_client(_client_data(profile_name="Otra Ana"))
    assert exc.value.code == "email_taken"


def test_las_contrasenas_distintas_se_rechazan_en_el_schema():
    with pytest.raises(ValidationError) as exc:
        _client_data(confirm_password="otra")

    [error] = exc.value.errors()
    assert error["loc"] == ("confirm_password",)
    assert "Las contraseñas no coinciden" in error["msg"]


# ── Login ────────────────────────────────────────────────────
def test_login_correcto_emite_un_token_con_el_rol(service):
    service.register_client(_client_data())

    token = service.login("ana@example.com", "123456")

    assert decode_access_token(token.access_token).role == "Client"


def test_correo_inexistente_y_contrasena_incorrecta_dan_el_mismo_error(service):
    service.register_client(_client_data())

    with pytest.raises(UnauthorizedError) as wrong_password:
        service.login("ana@example.com", "incorrecta")
    with pytest.raises(UnauthorizedError) as unknown_email:
        service.login("nadie@example.com", "123456")

    assert wrong_password.value.message == unknown_email.value.message == INVALID_CREDENTIALS
    assert wrong_password.value.code == unknown_email.value.code == "invalid_credentials"


# ── Saga de registro de dueño ────────────────────────────────
def test_registrar_dueno_crea_el_usuario_y_su_restaurante(service, users, catalog):
    token = service.register_owner(_owner_data(), catalog)

    assert users.users[token.user_id]["role"] == "Owner"
    assert catalog.calls_to("create_for_owner") == [(token.user_id, "Taquería El Güero", "Tacos")]
    assert catalog.owners == {1: token.user_id}


def test_el_usuario_se_confirma_antes_de_llamar_a_catalog(service, users):
    commits_al_llamar = []

    class RecordingCatalog(FakeCatalog):
        def create_for_owner(self, owner_id, name, food_type):
            commits_al_llamar.append(users.commits)
            return super().create_for_owner(owner_id, name, food_type)

    service.register_owner(_owner_data(), RecordingCatalog())

    assert commits_al_llamar == [1]


def test_si_catalog_falla_el_usuario_no_queda_guardado(service, users, catalog):
    catalog.fail_on("create_for_owner")

    with pytest.raises(RuntimeError):
        service.register_owner(_owner_data(), catalog)

    assert len(catalog.calls_to("create_for_owner")) == 1
    assert users.users == {}  # compensación: el usuario se borró
    assert users.commits == 2  # alta del usuario y su borrado


def test_el_error_de_negocio_de_catalog_llega_al_cliente_tras_compensar(service, users, catalog):
    catalog.fail_on("create_for_owner", ConflictError("El dueño ya tiene un restaurante"))

    with pytest.raises(ConflictError, match="ya tiene un restaurante"):
        service.register_owner(_owner_data(), catalog)

    assert users.users == {}


def test_si_la_compensacion_falla_queda_en_el_log_y_se_relanza_el_error_original(service, users, catalog, caplog):
    catalog.fail_on("create_for_owner", RuntimeError("Catálogo caído"))
    users.fail_on_delete = True

    with pytest.raises(RuntimeError, match="Catálogo caído"):
        service.register_owner(_owner_data(), catalog)

    assert "No se pudo compensar el registro del dueño" in caplog.text


def test_registrar_dueno_con_correo_repetido_no_llama_a_catalog(service, catalog):
    service.register_client(_client_data(email="maria@example.com"))

    with pytest.raises(ConflictError):
        service.register_owner(_owner_data(), catalog)

    assert catalog.calls == []


# ── Perfil ───────────────────────────────────────────────────
def test_obtener_perfil(service):
    token = service.register_client(_client_data())

    profile = service.get_profile(token.user_id)

    assert (profile.profile_name, profile.email, profile.role) == ("Ana", "ana@example.com", "Client")


def test_perfil_de_un_usuario_inexistente(service):
    with pytest.raises(NotFoundError):
        service.get_profile(99)


def test_actualizar_solo_los_campos_enviados(service):
    token = service.register_client(_client_data())

    profile = service.update_profile(token.user_id, UpdateProfileRequest(photo_url="https://img/ana.png"))

    assert (profile.profile_name, profile.photo_url) == ("Ana", "https://img/ana.png")


def test_actualizar_sin_campos_es_una_regla_de_negocio(service):
    token = service.register_client(_client_data())

    with pytest.raises(BusinessRuleError):
        service.update_profile(token.user_id, UpdateProfileRequest())


def test_actualizar_un_usuario_inexistente(service):
    with pytest.raises(NotFoundError):
        service.update_profile(99, UpdateProfileRequest(profile_name="Nadie"))
