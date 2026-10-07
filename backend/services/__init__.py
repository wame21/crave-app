"""
Servicios de dominio. Cada uno vive en `services/<dominio>/` y expone
`router = APIRouter(prefix="/<recurso>", ...)` en `router.py`; `main.py`
lo descubre y lo monta bajo /api/v1 sin que haya que editarlo.
"""
