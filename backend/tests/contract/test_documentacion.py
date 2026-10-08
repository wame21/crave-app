"""
La documentación de arquitectura (docs/arquitectura-soa.md) debe enlazar archivos
reales del repositorio y cubrir los principios SOA que pide la materia.
"""
import re
from pathlib import Path

DOCS = Path(__file__).resolve().parents[3] / "docs"
ARCHITECTURE = DOCS / "arquitectura-soa.md"
PRINCIPLES = (
    "Bajo acoplamiento",
    "Alta cohesión",
    "Reutilización",
    "Contrato de servicio",
    "Autonomía",
    "Abstracción",
    "Composición",
)


def _relative_links(markdown: str) -> list[str]:
    links = re.findall(r"\]\(([^)\s]+)\)", markdown)
    return [link.split("#")[0] for link in links if not link.startswith(("http://", "https://", "#"))]


def test_todos_los_enlaces_apuntan_a_archivos_que_existen():
    links = _relative_links(ARCHITECTURE.read_text(encoding="utf-8"))

    missing = [link for link in links if not (DOCS / link).exists()]

    assert len(links) > 30
    assert missing == []


def test_cubre_cada_principio_y_las_secciones_pedidas():
    text = ARCHITECTURE.read_text(encoding="utf-8")

    for principle in PRINCIPLES:
        assert f"| **{principle}** |" in text, principle
    for section in ("Vista general", "dueños de los datos", "Contratos", "Saga de registro de dueño"):
        assert section in text, section
    assert text.count("```mermaid") == 2  # diagrama de servicios y de la saga
