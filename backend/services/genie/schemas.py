"""
Peticiones y respuestas HTTP del servicio Genie.
"""
from pydantic import BaseModel, ConfigDict, Field

from contracts.catalog import RestaurantSummary
from services.genie.providers import MAX_MESSAGE_LENGTH


class ChatRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    message: str = Field(min_length=1, max_length=MAX_MESSAGE_LENGTH, description="El antojo del usuario")


class ChatResponse(BaseModel):
    reply: str
    restaurant_suggestions: list[RestaurantSummary] = Field(
        description="Hasta 3 restaurantes relacionados con el antojo"
    )
