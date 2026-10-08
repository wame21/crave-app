"""
El contrato publicado (docs/contracts/openapi-v1.json) debe coincidir con el que
genera la API: así ningún cambio de rutas, cuerpos o errores pasa sin querer.
"""
import difflib
import json

import pytest

from scripts import export_openapi
from scripts.export_openapi import CONTRACT_PATH, render_openapi


def test_el_contrato_publicado_coincide_con_la_api():
    published = CONTRACT_PATH.read_text(encoding="utf-8")
    generated = render_openapi()

    if generated != published:
        diff = difflib.unified_diff(
            published.splitlines(), generated.splitlines(), "publicado", "generado", lineterm="", n=2
        )
        pytest.fail(
            "La API cambió y docs/contracts/openapi-v1.json no está actualizado.\n"
            "Si el cambio es intencional: cd backend && python scripts/export_openapi.py\n\n"
            + "\n".join(list(diff)[:80]),
            pytrace=False,
        )


def test_el_contrato_cubre_todos_los_servicios_y_el_bff():
    contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))

    prefixes = {path.split("/")[3] for path in contract["paths"] if path.startswith("/api/v1/")}

    assert prefixes == {"auth", "users", "restaurants", "reviews", "favorites", "genie", "bff"}
    assert contract["info"]["version"] == "1.0.0"


def test_todas_las_rutas_de_la_api_documentan_el_formato_de_error():
    contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))

    for path, operations in contract["paths"].items():
        if not path.startswith("/api/v1/"):
            continue
        for method, operation in operations.items():
            error = operation["responses"]["422"]["content"]["application/json"]["schema"]["$ref"]
            assert error.endswith("/ErrorResponse"), f"{method.upper()} {path}"


def test_el_script_detecta_y_corrige_un_contrato_desactualizado(tmp_path, monkeypatch):
    contract = tmp_path / "openapi-v1.json"
    contract.write_text("{}\n", encoding="utf-8")
    monkeypatch.setattr(export_openapi, "CONTRACT_PATH", contract)

    assert export_openapi.run(["--check"]) == 1
    assert export_openapi.run([]) == 0
    assert contract.read_text(encoding="utf-8") == render_openapi()
    assert export_openapi.run(["--check"]) == 0
