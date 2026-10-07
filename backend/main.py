"""
Punto de entrada del backend de Crave App.
Levanta el servidor FastAPI con todos los routers registrados.

Para iniciar el servidor:
    uvicorn main:app --reload --port 8000

Documentación interactiva disponible en:
    http://localhost:8000/docs
    http://localhost:8000/redoc
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import auth, users, restaurants, reviews, favorites, genie

# ──────────────────────────────────────────────────────────────
# Creación de la aplicación
# ──────────────────────────────────────────────────────────────
app = FastAPI(
    title="Crave App API",
    description=(
        "Backend de **Crave**, la app para descubrir y reseñar restaurantes. \n\n"
        "## Autenticación\n"
        "Los endpoints protegidos requieren un header:\n"
        "`Authorization: Bearer <tu_token_jwt>`\n\n"
        "Obten tu token haciendo `POST /api/auth/login`."
    ),
    version="1.0.0",
    contact={
        "name": "Equipo Crave",
        "email": "dev@crave-app.com",
    },
)

# ──────────────────────────────────────────────────────────────
# CORS — permite requests desde la app Flutter y cualquier origen
# en desarrollo. Ajusta origins en producción.
# ──────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # En producción: ["https://tu-dominio.com"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ──────────────────────────────────────────────────────────────
# Registro de routers
# ──────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(restaurants.router)
app.include_router(reviews.router)
app.include_router(favorites.router)
app.include_router(genie.router)


# ──────────────────────────────────────────────────────────────
# Endpoint raíz de salud
# ──────────────────────────────────────────────────────────────
@app.get("/", tags=["Health"])
def root():
    """Verifica que el servidor está corriendo."""
    return {
        "status": "ok",
        "app": "Crave API",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
def health_check():
    """Health check para monitoreo."""
    return {"status": "healthy"}
