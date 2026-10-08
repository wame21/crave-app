# Crave App

App para descubrir y reseñar restaurantes: cliente **Flutter** + backend **FastAPI** + **PostgreSQL**.

El proyecto sigue una arquitectura orientada a servicios (SOA): ver [docs/arquitectura-soa.md](docs/arquitectura-soa.md). El plan de la migración está en la issue [#14](https://github.com/wame21/crave-app/issues/14).

## Estructura

```
.
├── backend/              # API FastAPI (ver backend/README.md)
├── db/init/              # Scripts .sql que Postgres ejecuta al crear el volumen
├── docs/                 # Arquitectura SOA y contrato OpenAPI publicado
├── docker-compose.yml    # PostgreSQL 17 para desarrollo local
├── lib/                  # App Flutter
│   ├── components/
│   ├── models/
│   ├── services/         # Clientes HTTP por dominio (auth, restaurants, reviews…)
│   └── views/
├── test/                 # Tests de Flutter
└── android/ ios/ linux/ macos/ web/ windows/
```

## Requisitos

- Docker con Compose v2
- Python 3 (probado con 3.14)
- Flutter 3.44 / Dart SDK `^3.11.4`

## 1. Base de datos

```bash
docker compose up -d --wait        # PostgreSQL 17 en localhost:5432, queda "healthy"
```

| Variable            | Valor por defecto |
|---------------------|-------------------|
| `POSTGRES_DB`       | `crave_db`        |
| `POSTGRES_USER`     | `crave`           |
| `POSTGRES_PASSWORD` | `crave_dev`       |
| `POSTGRES_PORT`     | `5432`            |

Cadena de conexión: `postgresql://crave:crave_dev@localhost:5432/crave_db`

Si el puerto 5432 está ocupado: `POSTGRES_PORT=5433 docker compose up -d --wait` (y usa ese puerto en `DATABASE_URL`, en `backend/.env`).

```bash
docker exec -it crave-postgres psql -U crave -d crave_db   # consola SQL
docker compose down                                         # detener (conserva los datos)
docker compose down -v && docker compose up -d --wait       # borrar datos y volver a correr db/init/
```

Los `.sql` de `db/init/` se ejecutan en orden alfabético **solo la primera vez** que se crea el volumen `crave_pgdata`. Si cambian (por ejemplo, después de un `git pull`), recrea el volumen con el último comando de arriba.

El seed crea dos clientes (`ana@example.com`, `carlos@example.com`) y dos dueños (`maria@example.com`, `jorge@example.com`), todos con la contraseña `123456`.

El proyecto de Compose se llama siempre `crave-app`, así que todos los worktrees del repo comparten el mismo contenedor (`crave-postgres`) y el mismo volumen.

## 2. Backend (FastAPI)

Con la base de datos del paso 1 ya levantada:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env               # y define JWT_SECRET_KEY (ver abajo)
uvicorn main:app --reload --port 8000
```

`uvicorn` debe ejecutarse dentro de `backend/`, porque los módulos se importan como `from config import …`.

El servidor **no arranca** si falta `JWT_SECRET_KEY` o si no puede conectarse a PostgreSQL (`DATABASE_URL`). Para generar una clave:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Las demás variables (`DATABASE_URL`, `CORS_ORIGINS`, `GEMINI_API_KEY`, …) están en `backend/.env.example` y se explican en [backend/README.md](backend/README.md).

- Salud: http://localhost:8000/health
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

La API está dividida en servicios bajo `/api/v1` (Identity, Catalog, Reviews, Favorites, Genie y el BFF de las pantallas); ver [backend/README.md](backend/README.md) y [docs/arquitectura-soa.md](docs/arquitectura-soa.md).

## 3. App (Flutter)

```bash
flutter pub get
flutter run                        # o: flutter run -d chrome / -d linux
```

La URL del backend se elige al compilar con `API_BASE_URL` (ver `lib/di.dart`). Por defecto es `http://10.0.2.2:8000/api/v1`, que es como el emulador de Android llega al `localhost` de la máquina. Para web, escritorio o simulador de iOS:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

En un teléfono físico, usa la IP de tu máquina en la red local. Para Flutter web, agrega además el origen de la app a `CORS_ORIGINS` en `backend/.env`.

## Verificación

```bash
flutter analyze
flutter test
cd backend && pytest               # algunas pruebas necesitan la base de datos del paso 1
```
