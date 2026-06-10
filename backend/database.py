"""
Cliente HTTP para Supabase usando la REST API directamente con httpx.
Esto nos permite usar cualquier tipo de API key (service key, anon key, etc.)
sin las restricciones de validación de la librería supabase-py.
"""
import httpx
from config import SUPABASE_URL, SUPABASE_KEY

# Base URL para la REST API de Supabase (PostgREST)
SUPABASE_REST_URL = f"{SUPABASE_URL}/rest/v1"

# Headers comunes para todas las peticiones
BASE_HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation",
}


class SupabaseClient:
    """
    Cliente simplificado para la API REST de Supabase.
    Soporta operaciones CRUD sobre cualquier tabla.
    """

    def __init__(self):
        self.base_url = SUPABASE_REST_URL
        self.headers = BASE_HEADERS.copy()
        self._client = httpx.Client(timeout=30.0)

    def table(self, table_name: str) -> "TableQuery":
        return TableQuery(self._client, self.base_url, self.headers, table_name)


class TableQuery:
    """Builder de queries para una tabla específica."""

    def __init__(self, client: httpx.Client, base_url: str, headers: dict, table: str):
        self._client = client
        self._base_url = base_url
        self._headers = headers.copy()
        self._table = table
        self._params: dict = {}
        self._order_params: list = []
        self._range_start: int | None = None
        self._range_end: int | None = None
        self._select_cols = "*"
        self._single = False

    def select(self, columns: str = "*") -> "TableQuery":
        self._select_cols = columns
        return self

    def eq(self, column: str, value) -> "TableQuery":
        self._params[column] = f"eq.{value}"
        return self

    def neq(self, column: str, value) -> "TableQuery":
        self._params[column] = f"neq.{value}"
        return self

    def ilike(self, column: str, pattern: str) -> "TableQuery":
        self._params[column] = f"ilike.{pattern}"
        return self

    def order(self, column: str, desc: bool = False) -> "TableQuery":
        direction = "desc" if desc else "asc"
        self._order_params.append(f"{column}.{direction}")
        return self

    def limit(self, count: int) -> "TableQuery":
        self._range_end = count - 1
        self._range_start = 0
        return self

    def range(self, start: int, end: int) -> "TableQuery":
        self._range_start = start
        self._range_end = end
        return self

    def single(self) -> "TableQuery":
        self._single = True
        self._headers["Accept"] = "application/vnd.pgrst.object+json"
        return self

    def _build_params(self) -> dict:
        params = {"select": self._select_cols}
        params.update(self._params)
        if self._order_params:
            params["order"] = ",".join(self._order_params)
        return params

    def _build_headers(self) -> dict:
        h = self._headers.copy()
        if self._range_start is not None and self._range_end is not None:
            h["Range"] = f"{self._range_start}-{self._range_end}"
            h["Range-Unit"] = "items"
        return h

    def execute(self) -> "QueryResult":
        """Ejecuta SELECT."""
        url = f"{self._base_url}/{self._table}"
        response = self._client.get(
            url, headers=self._build_headers(), params=self._build_params()
        )
        return _handle_response(response, self._single)

    def insert(self, data: dict | list) -> "TableQuery":
        """Prepara un INSERT."""
        self._insert_data = data
        self._operation = "insert"
        return _InsertQuery(self._client, self._base_url, self._headers, self._table, data)

    def update(self, data: dict) -> "TableQuery":
        """Prepara un UPDATE."""
        return _UpdateQuery(self._client, self._base_url, self._headers, self._table, data, self._params)

    def delete(self) -> "TableQuery":
        """Prepara un DELETE."""
        return _DeleteQuery(self._client, self._base_url, self._headers, self._table, self._params)


class _InsertQuery:
    def __init__(self, client, base_url, headers, table, data):
        self._client = client
        self._base_url = base_url
        self._headers = headers.copy()
        self._table = table
        self._data = data

    def execute(self) -> "QueryResult":
        url = f"{self._base_url}/{self._table}"
        response = self._client.post(url, headers=self._headers, json=self._data)
        return _handle_response(response)


class _UpdateQuery:
    def __init__(self, client, base_url, headers, table, data, params):
        self._client = client
        self._base_url = base_url
        self._headers = headers.copy()
        self._table = table
        self._data = data
        self._params = params

    def eq(self, column: str, value) -> "_UpdateQuery":
        self._params[column] = f"eq.{value}"
        return self

    def execute(self) -> "QueryResult":
        url = f"{self._base_url}/{self._table}"
        response = self._client.patch(url, headers=self._headers, params=self._params, json=self._data)
        return _handle_response(response)


class _DeleteQuery:
    def __init__(self, client, base_url, headers, table, params):
        self._client = client
        self._base_url = base_url
        self._headers = headers.copy()
        self._table = table
        self._params = params

    def eq(self, column: str, value) -> "_DeleteQuery":
        self._params[column] = f"eq.{value}"
        return self

    def execute(self) -> "QueryResult":
        url = f"{self._base_url}/{self._table}"
        response = self._client.delete(url, headers=self._headers, params=self._params)
        return _handle_response(response)


class QueryResult:
    """Encapsula la respuesta de Supabase."""
    def __init__(self, data, error=None):
        self.data = data
        self.error = error


def _handle_response(response: httpx.Response, single: bool = False) -> QueryResult:
    """Procesa la respuesta HTTP de Supabase y lanza excepciones claras en caso de error."""
    if response.status_code >= 400:
        try:
            error_detail = response.json()
        except Exception:
            error_detail = response.text
        raise Exception(f"Supabase error {response.status_code}: {error_detail}")

    if not response.content:
        return QueryResult(data=[] if not single else None)

    data = response.json()
    return QueryResult(data=data)


# Instancia global del cliente
supabase = SupabaseClient()
