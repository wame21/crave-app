"""Pruebas de config.py: variables obligatorias, opcionales y su formato."""
import importlib

import pytest

import config


@pytest.fixture
def recargar_config(monkeypatch):
    """Recarga config.py con el entorno del test, sin leer el .env del desarrollador."""
    monkeypatch.setattr("dotenv.load_dotenv", lambda *args, **kwargs: False)
    monkeypatch.setenv("JWT_SECRET_KEY", "clave-de-prueba")
    yield lambda: importlib.reload(config)
    monkeypatch.undo()
    importlib.reload(config)


@pytest.mark.parametrize("valor", [None, "", "   "])
def test_sin_jwt_secret_key_la_app_no_arranca(recargar_config, monkeypatch, valor):
    if valor is None:
        monkeypatch.delenv("JWT_SECRET_KEY")
    else:
        monkeypatch.setenv("JWT_SECRET_KEY", valor)

    with pytest.raises(RuntimeError, match="Falta la variable de entorno obligatoria JWT_SECRET_KEY"):
        recargar_config()


def test_cors_origins_se_lee_como_lista(recargar_config, monkeypatch):
    monkeypatch.setenv("CORS_ORIGINS", " http://localhost:3000 , ,https://crave.app")

    assert recargar_config().CORS_ORIGINS == ["http://localhost:3000", "https://crave.app"]


def test_valores_por_defecto(recargar_config, monkeypatch):
    for nombre in ("DATABASE_URL", "CORS_ORIGINS", "GEMINI_API_KEY"):
        monkeypatch.delenv(nombre, raising=False)

    cfg = recargar_config()

    assert cfg.DATABASE_URL == "postgresql://crave:crave_dev@localhost:5432/crave_db"
    assert cfg.CORS_ORIGINS == []
    assert cfg.GEMINI_API_KEY == ""
