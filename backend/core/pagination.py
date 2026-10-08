"""
Paginación común para todos los listados.

Uso en un router:

    @router.get("", response_model=Page[RestaurantSummary])
    def list_restaurants(page: PageParams = Depends()):
        items, total = service.list(limit=page.limit, offset=page.offset)
        return Page.create(items, total=total, params=page)
"""
from collections.abc import Sequence
from typing import Generic, TypeVar

from fastapi import Query
from pydantic import BaseModel, Field

T = TypeVar("T")

DEFAULT_LIMIT = 20
MAX_LIMIT = 100
# Tope de offset: sin él, un número enorme desborda el bigint de PostgreSQL (500).
MAX_OFFSET = 2**31 - 1


class PageParams:
    """Dependencia con los parámetros `limit` (1-100) y `offset` (≥ 0)."""

    def __init__(
        self,
        limit: int = Query(
            DEFAULT_LIMIT, ge=1, le=MAX_LIMIT, description="Elementos por página"
        ),
        offset: int = Query(0, ge=0, le=MAX_OFFSET, description="Elementos a saltar"),
    ):
        self.limit = limit
        self.offset = offset


class Page(BaseModel, Generic[T]):
    """
    Una página de resultados.

    `total` es el número total de elementos que cumplen el filtro,
    no el tamaño de esta página.
    """

    items: list[T]
    total: int = Field(ge=0)
    limit: int = Field(ge=1, le=MAX_LIMIT)
    offset: int = Field(ge=0)

    @classmethod
    def create(cls, items: Sequence[T], *, total: int, params: PageParams) -> "Page[T]":
        return cls(items=list(items), total=total, limit=params.limit, offset=params.offset)
