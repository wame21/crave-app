"""
Reglas de negocio del servicio Genie.
"""
from contracts.catalog import CatalogContract
from services.genie.providers import AIProvider, matching_restaurants
from services.genie.schemas import ChatResponse

# Restaurantes que se le muestran al proveedor y sugerencias que se devuelven.
CATALOG_SAMPLE = 20
MAX_SUGGESTIONS = 3


class GenieService:
    def __init__(self, catalog: CatalogContract, provider: AIProvider):
        self._catalog = catalog
        self._provider = provider

    def chat(self, message: str) -> ChatResponse:
        """
        Responde al antojo con el proveedor de IA y sugiere hasta 3
        restaurantes: los de la categoría pedida o, si no hay, los mejor
        calificados.
        """
        restaurants = self._catalog.list_active(limit=CATALOG_SAMPLE, order_by="rating")
        reply = self._provider.recommend(message, restaurants)
        suggestions = matching_restaurants(message, restaurants) or restaurants
        return ChatResponse(reply=reply, restaurant_suggestions=suggestions[:MAX_SUGGESTIONS])
