"""Pruebas de main.py: descubrimiento de routers, /api/v1, CORS y health."""
import textwrap
import uuid

import pytest
from fastapi import APIRouter
from fastapi.testclient import TestClient

import config
import main

ROUTER_SOURCE = """
from fastapi import APIRouter

router = APIRouter(prefix="/{prefix}")


@router.get("/ping")
def ping():
    return {{"from": "{prefix}"}}
"""


def _write(path, source=""):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(source))


@pytest.fixture
def fake_packages(tmp_path, monkeypatch):
    """Crea en disco un paquete de servicios y un BFF de prueba con nombres únicos."""
    services = f"services_{uuid.uuid4().hex}"
    bff = f"bff_{uuid.uuid4().hex}"
    root = tmp_path / services
    _write(root / "__init__.py")
    for name in ("reviews", "catalog"):
        _write(root / name / "__init__.py")
        _write(root / name / "router.py", ROUTER_SOURCE.format(prefix=name))
    _write(root / "sin_router" / "__init__.py")
    _write(root / "_privado" / "__init__.py")
    _write(root / "_privado" / "router.py", ROUTER_SOURCE.format(prefix="privado"))
    _write(tmp_path / bff / "__init__.py")
    _write(tmp_path / bff / "router.py", ROUTER_SOURCE.format(prefix="bff"))
    monkeypatch.syspath_prepend(str(tmp_path))
    return root, services, bff


def _prefixes(routers):
    return [router.prefix for router in routers]


# ── Descubrimiento ───────────────────────────────────────────
def test_discovers_services_alphabetically_and_then_the_bff(fake_packages):
    _, services, bff = fake_packages

    routers = main.discover_routers(services, extra_modules=[f"{bff}.router"])

    assert _prefixes(routers) == ["/catalog", "/reviews", "/bff"]


def test_missing_packages_are_skipped(fake_packages):
    _, services, _ = fake_packages

    assert main.discover_routers("no_existe", extra_modules=["tampoco.router"]) == []
    assert _prefixes(main.discover_routers(services, extra_modules=["tampoco.router"])) == [
        "/catalog",
        "/reviews",
    ]


def test_router_module_without_router_fails_loudly(fake_packages):
    root, services, _ = fake_packages
    _write(root / "roto" / "__init__.py")
    _write(root / "roto" / "router.py", "routes = []\n")

    with pytest.raises(TypeError, match="roto"):
        main.discover_routers(services, extra_modules=[])


def test_router_import_errors_are_not_hidden(fake_packages):
    root, services, _ = fake_packages
    _write(root / "con_error" / "__init__.py")
    _write(root / "con_error" / "router.py", "import modulo_que_no_existe\n")

    with pytest.raises(ModuleNotFoundError):
        main.discover_routers(services, extra_modules=[])


def test_discovered_routers_are_mounted_under_api_v1(monkeypatch):
    router = APIRouter(prefix="/demo")

    @router.get("/ping")
    def ping():
        return {"pong": True}

    monkeypatch.setattr(main, "discover_routers", lambda: [router])
    client = TestClient(main.create_app())

    assert client.get("/api/v1/demo/ping").json() == {"pong": True}
    assert client.get("/demo/ping").status_code == 404


# ── App ──────────────────────────────────────────────────────
def test_health_endpoints():
    client = TestClient(main.app)

    assert client.get("/health").json() == {"status": "healthy"}
    assert client.get("/").json()["api"] == "/api/v1"


def test_unknown_api_route_uses_common_error_format():
    response = TestClient(main.app).get("/api/v1/no-existe")

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


# ── CORS ─────────────────────────────────────────────────────
def test_no_cors_origins_means_no_cors():
    assert main.cors_options([]) is None


def test_explicit_origins_allow_credentials():
    options = main.cors_options(["http://localhost:3000"])

    assert options["allow_origins"] == ["http://localhost:3000"]
    assert options["allow_credentials"] is True


def test_wildcard_never_goes_with_credentials():
    options = main.cors_options(["*", "http://localhost:3000"])

    assert options["allow_origins"] == ["*"]
    assert options["allow_credentials"] is False


def test_cors_origins_come_from_config(monkeypatch):
    monkeypatch.setattr(config, "CORS_ORIGINS", ["http://localhost:3000"], raising=False)
    client = TestClient(main.create_app())
    preflight = {"Access-Control-Request-Method": "GET"}

    allowed = client.options("/health", headers={"Origin": "http://localhost:3000", **preflight})
    denied = client.options("/health", headers={"Origin": "http://evil.example", **preflight})

    assert allowed.headers["access-control-allow-origin"] == "http://localhost:3000"
    assert "access-control-allow-origin" not in denied.headers
