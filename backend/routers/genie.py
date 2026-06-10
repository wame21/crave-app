"""
Router del Genio de los Antojos (IA).
Endpoint:
  - POST /api/genie/chat  → Enviar mensaje al chatbot y recibir recomendación
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from config import GEMINI_API_KEY
from database import supabase
from utils.auth import get_current_user

router = APIRouter(prefix="/api/genie", tags=["Genio de los Antojos 🧞"])


class ChatMessage(BaseModel):
    message: str
    restaurant_id: Optional[int] = None  # Contexto opcional: restaurante actual


class ChatResponse(BaseModel):
    reply: str
    restaurant_suggestions: Optional[list] = None


# ─────────────────────────────────────────────────────────────
# POST /api/genie/chat
# ─────────────────────────────────────────────────────────────
@router.post("/chat", response_model=ChatResponse, summary="Chatear con el Genio")
def chat_with_genie(
    body: ChatMessage,
    current_user: dict = Depends(get_current_user),
):
    """
    Envía un mensaje al 'Genio de los Antojos' y recibe una recomendación
    de restaurante basada en lo que el usuario se antoja.

    Si GEMINI_API_KEY está configurada, usa Google Gemini.
    Si no, responde con sugerencias de la base de datos directamente.
    """
    user_message = body.message.strip()

    if not user_message:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El mensaje no puede estar vacío",
        )

    # ── Buscar restaurantes en la BD para dar contexto o sugerencias ──
    restaurants_result = (
        supabase.table("restaurants")
        .select("id_restaurant, name, food_type, overall_rating, address, description")
        .eq("is_active", True)
        .order("overall_rating", desc=True)
        .limit(20)
        .execute()
    )

    restaurants = restaurants_result.data or []

    # ── Intentar usar Gemini AI ──
    if GEMINI_API_KEY and GEMINI_API_KEY != "your_gemini_api_key_here":
        try:
            import google.generativeai as genai

            genai.configure(api_key=GEMINI_API_KEY)
            model = genai.GenerativeModel("gemini-1.5-flash")

            # Construir contexto con los restaurantes disponibles
            restaurant_list = "\n".join(
                f"- {r['name']} ({r['food_type']}, ⭐{r['overall_rating']}) - {r.get('address', 'Sin dirección')}"
                for r in restaurants
            )

            prompt = f"""
Eres el "Genio de los Antojos", un asistente amigable y emocionante de la app Crave 
que ayuda a los usuarios a encontrar el restaurante perfecto según sus antojos.

Responde siempre en español, de forma breve, positiva y recomendando opciones 
de la siguiente lista de restaurantes disponibles:

{restaurant_list}

El usuario dice: "{user_message}"

Responde de forma natural y entusiasta. Si el usuario menciona un tipo de comida o antojo,
recomienda el restaurante más apropiado de la lista. Sé conciso (máximo 3 oraciones).
"""
            response = model.generate_content(prompt)
            ai_reply = response.text

        except Exception as e:
            # Fallback si Gemini falla
            ai_reply = _simple_recommendation(user_message, restaurants)

    else:
        # Sin API key, usar lógica simple de palabras clave
        ai_reply = _simple_recommendation(user_message, restaurants)

    # Buscar restaurantes relevantes para sugerir con datos
    suggestions = _find_relevant_restaurants(user_message, restaurants)

    return ChatResponse(
        reply=ai_reply,
        restaurant_suggestions=suggestions[:3],  # Máximo 3 sugerencias
    )


def _simple_recommendation(user_message: str, restaurants: list) -> str:
    """
    Lógica simple de recomendación basada en palabras clave cuando
    no hay API key de Gemini disponible.
    """
    message_lower = user_message.lower()

    keyword_map = {
        "sushi": ["sushi", "japonés", "japonesa", "maki", "nigiri"],
        "pizza": ["pizza", "pizzería", "italiana", "italiano"],
        "hamburguesa": ["hamburguesa", "burger", "hamburguesería"],
        "tacos": ["tacos", "mexicano", "mexicana", "taco"],
        "café": ["café", "coffee", "cafetería", "capuchino", "latte"],
        "alitas": ["alitas", "pollo", "wings", "chicken"],
    }

    matched_type = None
    for food_type, keywords in keyword_map.items():
        if any(kw in message_lower for kw in keywords):
            matched_type = food_type
            break

    if matched_type:
        matching = [
            r for r in restaurants
            if matched_type.lower() in (r.get("food_type") or "").lower()
        ]
        if matching:
            best = matching[0]
            return (
                f"¡Perfecto antojo! 🔥 Te recomiendo **{best['name']}**, "
                f"uno de los mejores de {best['food_type']} con "
                f"⭐{best['overall_rating']} de calificación. ¡No te arrepentirás!"
            )

    # Recomendación general
    if restaurants:
        best = restaurants[0]
        return (
            f"¡Hmm, suena delicioso! 😋 Hoy te recomiendo probar **{best['name']}** "
            f"({best['food_type']}), que tiene ⭐{best['overall_rating']} estrellas. "
            f"¡Es una de las mejores opciones en la app!"
        )

    return (
        "¡Genial antojo! Estoy buscando las mejores opciones para ti. "
        "Por ahora no tenemos restaurantes disponibles, ¡pero pronto tendremos más!"
    )


def _find_relevant_restaurants(user_message: str, restaurants: list) -> list:
    """Busca restaurantes cuyo tipo de comida coincida con el mensaje del usuario."""
    message_lower = user_message.lower()
    relevant = []

    for r in restaurants:
        food_type = (r.get("food_type") or "").lower()
        if any(word in message_lower for word in food_type.split()):
            relevant.append(r)

    return relevant if relevant else restaurants[:3]
