"""
Configuración central del backend de Crave App.
Lee variables de entorno desde el archivo .env (plantilla: .env.example).
"""
import os

from dotenv import load_dotenv

load_dotenv()


def _require(name: str) -> str:
    """Devuelve la variable de entorno `name`; si falta, impide que la app arranque."""
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(
            f"Falta la variable de entorno obligatoria {name}. "
            "Defínela en backend/.env (usa backend/.env.example como plantilla)."
        )
    return value


def _split_csv(raw: str) -> list[str]:
    return [item.strip() for item in raw.split(",") if item.strip()]


# --- Base de datos (PostgreSQL) ---
# Por defecto apunta al contenedor de docker-compose.yml.
DATABASE_URL: str = os.getenv(
    "DATABASE_URL", "postgresql://crave:crave_dev@localhost:5432/crave_db"
)

# --- JWT ---
JWT_SECRET_KEY: str = _require("JWT_SECRET_KEY")
JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
    os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "1440")
)

# --- CORS ---
# Orígenes permitidos separados por comas. Vacío = no se permite ningún origen cruzado.
CORS_ORIGINS: list[str] = _split_csv(os.getenv("CORS_ORIGINS", ""))

# --- Gemini AI (opcional) ---
GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
