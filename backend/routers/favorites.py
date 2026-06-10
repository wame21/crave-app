"""
Router de favoritos.
Endpoints:
  - GET    /api/favorites/              → Mis restaurantes favoritos
  - POST   /api/favorites/{id}          → Agregar favorito
  - DELETE /api/favorites/{id}          → Quitar favorito
"""
from fastapi import APIRouter, Depends, HTTPException, status

from database import supabase
from utils.auth import get_current_user

router = APIRouter(prefix="/api/favorites", tags=["Favoritos"])


# ─────────────────────────────────────────────────────────────
# GET /api/favorites/
# ─────────────────────────────────────────────────────────────
@router.get("/", summary="Mis restaurantes favoritos")
def get_my_favorites(current_user: dict = Depends(get_current_user)):
    """
    Retorna la lista de restaurantes marcados como favoritos
    por el usuario autenticado, con info del restaurante.
    """
    user_id = int(current_user["sub"])

    result = (
        supabase.table("favorite_restaurants")
        .select(
            "id_favorite, id_client, id_restaurant, created_at, "
            "restaurants(name, food_type, overall_rating, address, phone)"
        )
        .eq("id_client", user_id)
        .order("created_at", desc=True)
        .execute()
    )

    favorites = result.data or []

    # Aplanar el join
    for fav in favorites:
        if fav.get("restaurants"):
            fav["restaurant_name"] = fav["restaurants"]["name"]
            fav["food_type"] = fav["restaurants"]["food_type"]
            fav["overall_rating"] = fav["restaurants"]["overall_rating"]
            fav["address"] = fav["restaurants"]["address"]
        fav.pop("restaurants", None)

    return {"favorites": favorites, "total": len(favorites)}


# ─────────────────────────────────────────────────────────────
# POST /api/favorites/{restaurant_id}
# ─────────────────────────────────────────────────────────────
@router.post("/{restaurant_id}", status_code=status.HTTP_201_CREATED, summary="Agregar favorito")
def add_favorite(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
):
    """
    Agrega un restaurante a los favoritos del usuario autenticado.
    Si ya existe, retorna 409 Conflict.
    """
    user_id = int(current_user["sub"])

    # Verificar que el restaurante existe
    restaurant = (
        supabase.table("restaurants")
        .select("id_restaurant")
        .eq("id_restaurant", restaurant_id)
        .execute()
    )
    if not restaurant.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restaurante no encontrado",
        )

    # Verificar si ya es favorito
    existing = (
        supabase.table("favorite_restaurants")
        .select("id_favorite")
        .eq("id_client", user_id)
        .eq("id_restaurant", restaurant_id)
        .execute()
    )
    if existing.data:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Este restaurante ya está en tus favoritos",
        )

    result = (
        supabase.table("favorite_restaurants")
        .insert({"id_client": user_id, "id_restaurant": restaurant_id})
        .execute()
    )

    return {"message": "Restaurante agregado a favoritos", "favorite": result.data[0]}


# ─────────────────────────────────────────────────────────────
# DELETE /api/favorites/{restaurant_id}
# ─────────────────────────────────────────────────────────────
@router.delete("/{restaurant_id}", summary="Quitar favorito")
def remove_favorite(
    restaurant_id: int,
    current_user: dict = Depends(get_current_user),
):
    """
    Elimina un restaurante de los favoritos del usuario autenticado.
    """
    user_id = int(current_user["sub"])

    # Verificar que existe el favorito
    existing = (
        supabase.table("favorite_restaurants")
        .select("id_favorite")
        .eq("id_client", user_id)
        .eq("id_restaurant", restaurant_id)
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Este restaurante no está en tus favoritos",
        )

    supabase.table("favorite_restaurants").delete().eq(
        "id_client", user_id
    ).eq("id_restaurant", restaurant_id).execute()

    return {"message": "Restaurante eliminado de favoritos"}
