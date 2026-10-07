"""
Configuración central del backend de Crave App.
Lee variables de entorno desde el archivo .env
"""
import os
from dotenv import load_dotenv

load_dotenv()

# --- Supabase ---
SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")

# --- JWT ---
JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "cambia-esta-clave-en-produccion")
JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
    os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "1440")
)

# --- Gemini AI ---
GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
