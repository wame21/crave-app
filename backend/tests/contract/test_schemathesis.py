"""
Pruebas de contrato con Schemathesis: genera peticiones a partir del OpenAPI de
la API y comprueba que cada respuesta cumpla lo publicado (código de estado
documentado, cuerpo según su esquema, content-type) y que nunca haya un 500.

Corren contra la app real con la BD sembrada (docker compose up -d --wait). Para
no ensuciar la BD solo se prueban las operaciones que no escriben: todos los
GET (sin sesión y con la sesión de un cliente del seed), el login y el chat
del Genio. Las escrituras las cubren las pruebas de integración de cada servicio.
"""
import psycopg
import pytest
import schemathesis
from hypothesis import HealthCheck, settings

import main
from config import DATABASE_URL
from contracts.registry import get_catalog, get_identity
from core.security import create_access_token
from services.catalog.provider import CatalogProvider
from services.identity.provider import IdentityProvider


def _app():
    app = main.create_app()
    # Las implementaciones reales de los contratos, sin depender del registro global.
    app.dependency_overrides[get_catalog] = CatalogProvider
    app.dependency_overrides[get_identity] = IdentityProvider
    return app


schema = schemathesis.openapi.from_asgi("/openapi.json", _app())
reads = schema.include(method="GET")
login_and_genie = schema.include(method="POST", path_regex=r"/(auth/login|genie/chat)$")

contract_settings = settings(max_examples=30, deadline=None, suppress_health_check=list(HealthCheck))


@pytest.fixture(scope="module")
def client_session() -> dict[str, str]:
    """Header de autenticación de Ana, una clienta del seed."""
    with psycopg.connect(DATABASE_URL) as conn:
        [ana] = conn.execute("SELECT id_user FROM identity.users WHERE email = 'ana@example.com'").fetchone()
    return {"Authorization": f"Bearer {create_access_token(ana, 'ana@example.com', 'Client')}"}


@reads.parametrize()
@contract_settings
def test_las_lecturas_publicas_cumplen_el_contrato(case):
    case.call_and_validate()


def _session_for(case, session: dict[str, str]) -> dict[str, str] | None:
    """
    La sesión solo se agrega a los casos positivos. Los negativos (por ejemplo,
    sin `Authorization`) tienen que llegar tal como los generó Schemathesis
    para comprobar que la API los rechaza.
    """
    meta = case.meta
    return session if meta is None or meta.generation.mode.is_positive else None


@reads.parametrize()
@contract_settings
def test_las_lecturas_con_sesion_cumplen_el_contrato(case, client_session):
    case.call_and_validate(headers=_session_for(case, client_session))


@login_and_genie.parametrize()
@contract_settings
def test_el_login_y_el_genio_cumplen_el_contrato(case, client_session):
    case.call_and_validate(headers=_session_for(case, client_session))
