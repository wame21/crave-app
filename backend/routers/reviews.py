"""
Router de reseñas.
Endpoints:
  - GET  /api/reviews/restaurant/{restaurant_id}  → Reseñas de un restaurante
  - GET  /api/reviews/me                          → Mis reseñas
  - POST /api/reviews/                            → Crear reseña
  - DELETE /api/reviews/{id}                      → Eliminar reseña propia
"""
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from database import supabase
from schemas.review import ReviewCreate, ReviewResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/api/reviews", tags=["Reseñas"])


def _recalculate_restaurant_rating(restaurant_id: int) -> None:
    """
    Recalcula el overall_rating del restaurante basado en todas sus reseñas aprobadas.
    Promedia los tres sub-ratings: comida, servicio y ambiente.
    """
    reviews_result = (
        supabase.table("reviews")
        .select("rating_food, rating_service, rating_atmosphere")
        .eq("id_restaurant", restaurant_id)
        .eq("status", "Approved")
        .execute()
    )

    reviews = reviews_result.data or []
    if not reviews:
        new_rating = 0.0
    else:
        total = sum(
            (r["rating_food"] + r["rating_service"] + r["rating_atmosphere"]) / 3
            for r in reviews
            if r["rating_food"] and r["rating_service"] and r["rating_atmosphere"]
        )
        new_rating = round(total / len(reviews), 2) if reviews else 0.0

    supabase.table("restaurants").update({"overall_rating": new_rating}).eq(
        "id_restaurant", restaurant_id
    ).execute()


# ─────────────────────────────────────────────────────────────
# GET /api/reviews/me
# ─────────────────────────────────────────────────────────────
@router.get("/me", summary="Mis reseñas publicadas")
def get_my_reviews(current_user: dict = Depends(get_current_user)):
    """
    Retorna todas las reseñas creadas por el usuario autenticado,
    incluyendo el nombre del restaurante de cada una.
    """
    user_id = int(current_user["sub"])

    result = (
        supabase.table("reviews")
        .select("*, restaurants(name)")
        .eq("id_client", user_id)
        .order("created_at", desc=True)
        .execute()
    )

    reviews = result.data or []

    # Aplanar el join restaurants(name) en el resultado
    for review in reviews:
        if review.get("restaurants"):
            review["restaurant_name"] = review["restaurants"]["name"]
        del review["restaurants"]

    return {"reviews": reviews}


# ─────────────────────────────────────────────────────────────
# GET /api/reviews/restaurant/{restaurant_id}
# ─────────────────────────────────────────────────────────────
@router.get(
    "/restaurant/{restaurant_id}",
    summary="Reseñas de un restaurante",
)
def get_restaurant_reviews(
    restaurant_id: int,
    limit: int = 50,
    offset: int = 0,
):
    """
    Retorna las reseñas aprobadas de un restaurante específico,
    incluyendo el nombre y foto del cliente que la publicó.
    """
    result = (
        supabase.table("reviews")
        .select("*, users(profile_name, photo_url)")
        .eq("id_restaurant", restaurant_id)
        .eq("status", "Approved")
        .order("created_at", desc=True)
        .range(offset, offset + limit - 1)
        .execute()
    )

    reviews = result.data or []

    for review in reviews:
        if review.get("users"):
            review["client_name"] = review["users"]["profile_name"]
            review["client_photo"] = review["users"].get("photo_url")
        review.pop("users", None)

    return {"reviews": reviews, "total": len(reviews)}


# ─────────────────────────────────────────────────────────────
# POST /api/reviews/
# ─────────────────────────────────────────────────────────────
@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    summary="Crear una reseña",
)
def create_review(
    body: ReviewCreate,
    current_user: dict = Depends(get_current_user),
):
    """
    Crea una nueva reseña para un restaurante.
    Solo usuarios con rol 'Client' pueden publicar reseñas.
    El status inicial es 'Pending' (requiere moderación).
    """
    if current_user.get("role") != "Client":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los clientes pueden publicar reseñas",
        )

    user_id = int(current_user["sub"])

    # Verificar que el restaurante existe
    restaurant = (
        supabase.table("restaurants")
        .select("id_restaurant")
        .eq("id_restaurant", body.id_restaurant)
        .single()
        .execute()
    )

    if not restaurant.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restaurante no encontrado",
        )

    # Insertar la reseña
    new_review_result = (
        supabase.table("reviews")
        .insert(
            {
                "id_client": user_id,
                "id_restaurant": body.id_restaurant,
                "rating_food": body.rating_food,
                "rating_service": body.rating_service,
                "rating_atmosphere": body.rating_atmosphere,
                "comment": body.comment,
                "photo_gallery": body.photo_gallery or [],
                "status": "Approved",  # Auto-aprobado; cambiar a 'Pending' si quieres moderación
            }
        )
        .execute()
    )

    new_review = new_review_result.data[0]

    # Recalcular calificación general del restaurante
    _recalculate_restaurant_rating(body.id_restaurant)

    return {"message": "Reseña publicada exitosamente", "review": new_review}


# ─────────────────────────────────────────────────────────────
# DELETE /api/reviews/{id}
# ─────────────────────────────────────────────────────────────
@router.delete("/{review_id}", summary="Eliminar una reseña propia")
def delete_review(
    review_id: int,
    current_user: dict = Depends(get_current_user),
):
    """
    Elimina una reseña. Solo el autor de la reseña puede eliminarla.
    Recalcula el rating del restaurante tras eliminar.
    """
    user_id = int(current_user["sub"])

    # Buscar la reseña y verificar que pertenece al usuario
    review_result = (
        supabase.table("reviews")
        .select("id_review, id_client, id_restaurant")
        .eq("id_review", review_id)
        .single()
        .execute()
    )

    if not review_result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reseña no encontrada",
        )

    review = review_result.data
    if review["id_client"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No puedes eliminar la reseña de otro usuario",
        )

    supabase.table("reviews").delete().eq("id_review", review_id).execute()

    # Recalcular rating del restaurante
    _recalculate_restaurant_rating(review["id_restaurant"])

    return {"message": "Reseña eliminada exitosamente"}
