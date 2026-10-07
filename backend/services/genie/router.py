"""
Rutas HTTP del servicio Genie: /genie.
"""
import os
from functools import cache

from fastapi import APIRouter, Depends

import config
from contracts.catalog import CatalogContract
from contracts.registry import get_catalog
from core.errors import ErrorResponse
from core.security import CurrentUser, get_current_user
from services.genie.providers import (
    DEFAULT_GEMINI_MODEL,
    AIProvider,
    FallbackProvider,
    GeminiProvider,
    KeywordProvider,
)
from services.genie.schemas import ChatRequest, ChatResponse
from services.genie.service import GenieService


@cache
def default_provider() -> AIProvider:
    """Gemini (GEMINI_API_KEY y GEMINI_MODEL) con respaldo por palabras clave."""
    model = os.getenv("GEMINI_MODEL", "").strip() or DEFAULT_GEMINI_MODEL
    return FallbackProvider(GeminiProvider(config.GEMINI_API_KEY, model), KeywordProvider())


def get_ai_provider() -> AIProvider:
    """Dependencia del proveedor de IA; las pruebas la sustituyen."""
    return default_provider()


router = APIRouter(prefix="/genie", tags=["Genio de los Antojos"])


@router.post(
    "/chat",
    response_model=ChatResponse,
    summary="Chatear con el Genio",
    responses={401: {"model": ErrorResponse, "description": "Falta el token o es inválido"}},
)
def chat(
    body: ChatRequest,
    user: CurrentUser = Depends(get_current_user),
    catalog: CatalogContract = Depends(get_catalog),
    provider: AIProvider = Depends(get_ai_provider),
) -> ChatResponse:
    """
    Recomienda restaurantes según el antojo del usuario (máximo 500 caracteres).

    Usa Google Gemini si hay `GEMINI_API_KEY`. Sin clave, o si Gemini falla,
    responde con recomendaciones por palabras clave: el endpoint siempre funciona.
    """
    return GenieService(catalog, provider).chat(body.message)
