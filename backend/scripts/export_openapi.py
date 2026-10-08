"""
Exporta el contrato OpenAPI de la API a docs/contracts/openapi-v1.json, con las
claves ordenadas para que los diffs entre versiones sean estables.

    cd backend
    python scripts/export_openapi.py          # actualiza el archivo
    python scripts/export_openapi.py --check  # falla si el archivo está desactualizado

tests/contract/test_openapi.py hace la misma comprobación que --check, así que
un cambio de contrato sin regenerar el archivo rompe las pruebas.
"""
import argparse
import json
import os
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[1]
CONTRACT_PATH = BACKEND_DIR.parent / "docs" / "contracts" / "openapi-v1.json"


def render_openapi() -> str:
    """El OpenAPI de la app como JSON con claves ordenadas y salto de línea final."""
    # El contrato no depende del secreto JWT, pero config.py lo exige para importar.
    os.environ.setdefault("JWT_SECRET_KEY", "solo-para-exportar-el-contrato")
    if str(BACKEND_DIR) not in sys.path:
        sys.path.insert(0, str(BACKEND_DIR))
    import main

    return json.dumps(main.create_app().openapi(), indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def run(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Exporta el contrato OpenAPI de la API v1.")
    parser.add_argument("--check", action="store_true", help="no escribe; falla si el archivo está desactualizado")
    args = parser.parse_args(argv)

    current = render_openapi()
    if args.check:
        if not CONTRACT_PATH.exists() or CONTRACT_PATH.read_text(encoding="utf-8") != current:
            print(f"{CONTRACT_PATH} está desactualizado. Ejecuta: python scripts/export_openapi.py", file=sys.stderr)
            return 1
        print(f"{CONTRACT_PATH} está al día.")
        return 0

    CONTRACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONTRACT_PATH.write_text(current, encoding="utf-8")
    print(f"Contrato exportado a {CONTRACT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(run())
