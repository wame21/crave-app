"""
Router de restaurantes.
Endpoints:
  - GET  /api/restaurants/home          → Datos para la pantalla Home
  - GET  /api/restaurants/categories    → Lista de categorías
  - GET  /api/restaurants/              → Listar/buscar restaurantes
  - GET  /api/restaurants/me            → Restaurante del dueño autenticado
  - GET  /api/restaurants/{id}          → Detalle de un restaurante
  - PUT  /api/restaurants/{id}          → Editar restaurante (solo Owner)
"""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status

from database import supabase
from schemas.restaurant import RestaurantBase, RestaurantUpdate
from utils.auth import get_current_user

router = APIRouter(prefix="/api/restaurants", tags=["Restaurantes"])

# Categorías disponibles en la app
CATEGORIES = [
    "Tacos", "Pizza", "Sushi", "Hamburguesas", "Café",
    "Alitas", "Italiana", "Mexicana", "China", "Mariscos",
]


# ─────────────────────────────────────────────────────────────
# GET /api/restaurants/categories
# ─────────────────────────────────────────────────────────────
@router.get("/categories", summary="Listar categorías de comida")
def get_categories():
    """Retorna la lista estática de categorías disponibles."""
    return {"categories": CATEGORIES}


# ─────────────────────────────────────────────────────────────
# GET /api/restaurants/home
# ─────────────────────────────────────────────────────────────
@router.get("/home", summary="Datos para la pantalla Home")
def get_home_data():
    """
    Retorna tres secciones de restaurantes para la pantalla principal:
    - destacados: Los 5 mejor calificados (para el banner)
    - mejor_valorados: Top 10 por calificación
    - recomendados: Restaurantes activos aleatorios
    - novedades: Los 10 más recientes (por id)
    """
    base_query = (
        supabase.table("restaurants")
        .select(
            "id_restaurant, name, food_type, overall_rating, address, phone, is_active"
        )
        .eq("is_active", True)
    )

    # Destacados (mejor calificados para el banner)
    destacados_result = (
        base_query.order("overall_rating", desc=True).limit(5).execute()
    )

    # Mejor valorados
    mejor_valorados_result = (
        base_query.order("overall_rating", desc=True).limit(10).execute()
    )

    # Novedades (más recientes por id)
    novedades_result = (
        base_query.order("id_restaurant", desc=True).limit(10).execute()
    )

    return {
        "destacados": destacados_result.data or [],
        "mejor_valorados": mejor_valorados_result.data or [],
        "recomendados": mejor_valorados_result.data or [],  # Misma lógica por ahora
        "novedades": novedades_result.data or [],
    }


# ─────────────────────────────────────────────────────────────
# GET /api/restaurants/me  (el restaurante del dueño)
# ─────────────────────────────────────────────────────────────
@router.get("/me", response_model=RestaurantBase, summary="Mi restaurante (Owner)")
def get_my_restaurant(current_user: dict = Depends(get_current_user)):
    """
    Retorna el restaurante del dueño autenticado.
    Solo disponible para usuarios con rol 'Owner'.
    """
    if current_user.get("role") != "Owner":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los dueños tienen restaurante",
        )

    user_id = int(current_user["sub"])

    result = (
        supabase.table("restaurants")
        .select("*")
        .eq("id_owner", user_id)
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No tienes un restaurante registrado",
        )

    return result.data


# ─────────────────────────────────────────────────────────────
# GET /api/restaurants/
# ─────────────────────────────────────────────────────────────
@router.get("/", summary="Listar y buscar restaurantes")
def list_restaurants(
    q: Optional[str] = Query(None, description="Búsqueda por nombre"),
    category: Optional[str] = Query(None, description="Filtrar por tipo de comida"),
    sort: Optional[str] = Query(
        "rating",
        description="Ordenar por: 'rating' | 'new'",
    ),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """
    Lista restaurantes activos con soporte para búsqueda y filtros.
    """
    query = (
        supabase.table("restaurants")
        .select(
            "id_restaurant, name, food_type, overall_rating, address, phone, "
            "is_active, description, price_range"
        )
        .eq("is_active", True)
    )

    # Filtro por nombre
    if q:
        query = query.ilike("name", f"%{q}%")

    # Filtro por categoría
    if category:
        query = query.ilike("food_type", f"%{category}%")

    # Ordenamiento
    if sort == "new":
        query = query.order("id_restaurant", desc=True)
    else:  # default: rating
        query = query.order("overall_rating", desc=True)

    result = query.range(offset, offset + limit - 1).execute()

    return {
        "total": len(result.data or []),
        "restaurants": result.data or [],
    }


# ─────────────────────────────────────────────────────────────
# GET /api/restaurants/{id}
# ─────────────────────────────────────────────────────────────
@router.get(
    "/{restaurant_id}",
    response_model=RestaurantBase,
    summary="Detalle de un restaurante",
)
def get_restaurant(restaurant_id: int):
    """
    Retorna la información completa de un restaurante por su ID.
    """
    result = (
        supabase.table("restaurants")
        .select("*")
        .eq("id_restaurant", restaurant_id)
        .single()
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restaurante no encontrado",
        )

    return result.data


# ─────────────────────────────────────────────────────────────
# PUT /api/restaurants/{id}
# ─────────────────────────────────────────────────────────────
@router.put(
    "/{restaurant_id}",
    response_model=RestaurantBase,
    summary="Editar restaurante (solo Owner)",
)
def update_restaurant(
    restaurant_id: int,
    body: RestaurantUpdate,
    current_user: dict = Depends(get_current_user),
):
    """
    Actualiza la información de un restaurante.
    Solo el dueño del restaurante puede editarlo.
    """
    if current_user.get("role") != "Owner":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los dueños pueden editar restaurantes",
        )

    user_id = int(current_user["sub"])

    # Verificar que el restaurante pertenece al owner autenticado
    ownership = (
        supabase.table("restaurants")
        .select("id_restaurant")
        .eq("id_restaurant", restaurant_id)
        .eq("id_owner", user_id)
        .execute()
    )

    if not ownership.data:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para editar este restaurante",
        )

    update_data = body.model_dump(exclude_none=True)

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se proporcionaron campos para actualizar",
        )

    result = (
        supabase.table("restaurants")
        .update(update_data)
        .eq("id_restaurant", restaurant_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restaurante no encontrado",
        )

    return result.data[0]
