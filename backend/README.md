# Crave App — Backend API

Backend construido con **FastAPI** sobre **PostgreSQL** (psycopg 3). Se está migrando a una arquitectura orientada a servicios por olas; el plan está en la issue [#14](https://github.com/wame21/crave-app/issues/14).

## Estado actual

Ya está listo el kit común sobre el que se construyen los servicios (Ola 1):

- **Capa de datos** (`database.py`): pool de conexiones y una transacción por request.
- **Contrato de la API** (`core/`): rutas bajo `/api/v1`, formato único de error, paginación y control de acceso por rol.
- **Contratos entre servicios** (`contracts/`): interfaces que cada servicio implementa y los demás consumen.
- **Esquema y datos de prueba** en `db/init/`, en la raíz del repo.

Sobre ese kit, la Ola 2 (issues [#20](https://github.com/wame21/crave-app/issues/20)–[#24](https://github.com/wame21/crave-app/issues/24)) implementó un servicio por dominio en `services/`: Identity, Catalog, Reviews, Favorites y Genie. Cada uno es dueño de su esquema de PostgreSQL y usa los datos de los demás solo a través de `contracts/`.

| Servicio | Rutas (bajo `/api/v1`) | Esquema |
|---|---|---|
| Identity | `POST /auth/login`, `POST /auth/register/client`, `POST /auth/register/owner`, `GET`/`PUT /users/me` | `identity` |
| Catalog | `GET /restaurants`, `GET /restaurants/categories`, `GET /restaurants/me`, `GET`/`PUT /restaurants/{id}` | `catalog` |
| Reviews | `GET /reviews/restaurant/{id}`, `GET /reviews/me`, `POST /reviews`, `DELETE /reviews/{id}` | `reviews` |
| Favorites | `GET /favorites`, `GET`/`POST`/`DELETE /favorites/{restaurant_id}` | `favorites` |
| Genie | `POST /genie/chat` | — |

La lista completa, con los cuerpos y los errores de cada ruta, está en `/docs`.

## Estructura

```
backend/
├── main.py              # Crea la app y monta los routers de services/ y bff/ bajo /api/v1
├── config.py            # Variables de entorno (ver .env.example)
├── database.py          # Pool de PostgreSQL, dependencia DbConn y helpers fetch_one/fetch_all/execute
├── core/
│   ├── errors.py        # Excepciones de dominio y formato único de error
│   ├── pagination.py    # Page[T] y PageParams
│   └── security.py      # JWT, get_current_user, get_optional_user, require_role
├── contracts/           # CatalogContract, IdentityContract y su registro
├── services/<dominio>/  # router, schemas, service, repository (y provider si implementa un contrato) + tests/
├── tests/               # Pruebas del kit; fakes.py tiene FakeCatalog y FakeIdentity
├── requirements.txt
└── .env.example         # Plantilla de backend/.env (que no se versiona)
```

## Instalación y ejecución

Primero levanta PostgreSQL desde la raíz del repo con `docker compose up -d --wait`. Después:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env               # y define JWT_SECRET_KEY
uvicorn main:app --reload --port 8000
```

`uvicorn` debe ejecutarse dentro de `backend/`, porque los módulos se importan como `from config import …`.

Al arrancar, la app abre el pool de conexiones y espera a la base de datos: si no responde en 10 segundos, el servidor no arranca.

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Variables de entorno

Se leen de `backend/.env`:

| Variable | Obligatoria | Valor por defecto | Para qué sirve |
|---|---|---|---|
| `JWT_SECRET_KEY` | Sí | — | Firma de los tokens. Genérala con `python -c "import secrets; print(secrets.token_urlsafe(32))"` |
| `DATABASE_URL` | No | `postgresql://crave:crave_dev@localhost:5432/crave_db` | Conexión a PostgreSQL (coincide con `docker-compose.yml`) |
| `JWT_ALGORITHM` | No | `HS256` | Algoritmo de firma |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | No | `1440` | Duración del token |
| `CORS_ORIGINS` | No | vacío | Orígenes permitidos, separados por comas. Vacío = ningún origen cruzado. `*` desactiva las credenciales |
| `GEMINI_API_KEY` | No | vacío | Sin clave, el Genio recomienda por palabras clave |

## Contrato de la API

**Versión.** Todas las rutas de los servicios cuelgan de `/api/v1`.

**Autenticación.** Los endpoints protegidos requieren el header `Authorization: Bearer <token>`. Sin token responden 401; con un rol distinto del requerido, 403.

**Errores.** Todos responden con el mismo formato:

```json
{"error": {"code": "not_found", "message": "Restaurante no encontrado"}}
```

Los errores de validación (422) agregan `details` con el campo y el motivo. Los 500 nunca exponen detalles internos.

**Paginación.** Los listados reciben `limit` (de 1 a 100, por defecto 20) y `offset`, y responden `{"items": [...], "total": N, "limit": 20, "offset": 0}`, donde `total` es el número de resultados del filtro, no el tamaño de la página.

## Cómo agregar un servicio (Ola 2)

1. Crea `services/<dominio>/router.py` con `router = APIRouter(prefix="/<recurso>", tags=[...])`. `main.py` lo descubre y lo monta bajo `/api/v1` sin editarlo.
2. Recibe la conexión con `db: DbConn` y consulta solo el esquema de tu servicio, siempre con parámetros (`%s`), nunca interpolando SQL.
3. Lanza las excepciones de `core.errors` (`NotFoundError`, `ConflictError`, …) en lugar de `HTTPException`.
4. Protege rutas con `Depends(get_current_user)` o `Depends(require_role("Owner"))`.
5. Para datos de otro servicio, usa su contrato (`Depends(get_catalog)`, `Depends(get_identity)`), nunca sus tablas. En las pruebas, sustitúyelo con `app.dependency_overrides` y los fakes de `tests/fakes.py`.

## Pruebas

```bash
cd backend
pytest                             # o, desde la raíz del repo: pytest backend
```

`tests/test_database.py` y `tests/test_schema.py` usan el PostgreSQL del contenedor y revierten todo lo que escriben. Si `test_schema.py` falla después de un cambio en `db/init/`, recrea el volumen con `docker compose down -v && docker compose up -d --wait`.

## Datos de prueba

El seed crea dos clientes (`ana@example.com`, `carlos@example.com`) y dos dueños (`maria@example.com`, `jorge@example.com`), todos con la contraseña `123456`, además de 10 restaurantes, reseñas y favoritos.
