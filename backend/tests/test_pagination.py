"""Pruebas de la paginación común (core/pagination.py)."""
import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from pydantic import BaseModel, ValidationError

from core.errors import register_error_handlers
from core.pagination import DEFAULT_LIMIT, MAX_LIMIT, Page, PageParams


class Item(BaseModel):
    id: int


ITEMS = [Item(id=i) for i in range(1, 46)]


@pytest.fixture
def client():
    app = FastAPI()
    register_error_handlers(app)

    @app.get("/items", response_model=Page[Item])
    def list_items(page: PageParams = Depends()):
        window = ITEMS[page.offset : page.offset + page.limit]
        return Page.create(window, total=len(ITEMS), params=page)

    return TestClient(app)


def test_default_page_params(client):
    body = client.get("/items").json()

    assert body["limit"] == DEFAULT_LIMIT
    assert body["offset"] == 0
    assert len(body["items"]) == DEFAULT_LIMIT


def test_total_is_the_full_count_not_the_page_size(client):
    body = client.get("/items", params={"limit": 10, "offset": 40}).json()

    assert body == {
        "items": [{"id": i} for i in range(41, 46)],
        "total": 45,
        "limit": 10,
        "offset": 40,
    }


def test_max_limit_is_accepted(client):
    assert client.get("/items", params={"limit": MAX_LIMIT}).status_code == 200


@pytest.mark.parametrize(
    "params, field",
    [
        ({"limit": 0}, "query.limit"),
        ({"limit": MAX_LIMIT + 1}, "query.limit"),
        ({"offset": -1}, "query.offset"),
    ],
)
def test_out_of_range_params_are_rejected_with_common_format(client, params, field):
    response = client.get("/items", params=params)

    assert response.status_code == 422
    error = response.json()["error"]
    assert error["code"] == "validation_error"
    assert error["details"][0]["field"] == field


def test_page_rejects_negative_total():
    with pytest.raises(ValidationError):
        Page[Item](items=[], total=-1, limit=10, offset=0)


def test_page_is_documented_with_its_item_type(client):
    schemas = client.get("/openapi.json").json()["components"]["schemas"]
    page_schema = next(s for name, s in schemas.items() if name.startswith("Page"))

    assert set(page_schema["required"]) == {"items", "total", "limit", "offset"}
    assert page_schema["properties"]["items"]["items"] == {"$ref": "#/components/schemas/Item"}
