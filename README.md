# Crave App

App para descubrir y reseñar restaurantes: cliente **Flutter** + backend **FastAPI** + **PostgreSQL**.

El proyecto se está migrando a una arquitectura orientada a servicios (SOA) por olas; el plan está en la issue [#14](https://github.com/wame21/crave-app/issues/14).

## Estructura

```
.
├── backend/              # API FastAPI (routers, schemas, utils)
├── db/init/              # Scripts .sql que Postgres ejecuta al crear el volumen
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

Si el puerto 5432 está ocupado: `POSTGRES_PORT=5433 docker compose up -d --wait`.

```bash
docker exec -it crave-postgres psql -U crave -d crave_db   # consola SQL
docker compose down                                         # detener (conserva los datos)
docker compose down -v && docker compose up -d --wait       # borrar datos y volver a correr db/init/
```

Los `.sql` de `db/init/` se ejecutan en orden alfabético **solo la primera vez** que se crea el volumen `crave_pgdata`.

El proyecto de Compose se llama siempre `crave-app`, así que todos los worktrees del repo comparten el mismo contenedor (`crave-postgres`) y el mismo volumen.

## 2. Backend (FastAPI)

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

`uvicorn` debe ejecutarse dentro de `backend/`, porque los módulos se importan como `from config import …`.

- Salud: http://localhost:8000/health
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

Variables de entorno opcionales (en `backend/.env`, que no se versiona): `JWT_SECRET_KEY`, `JWT_ALGORITHM`, `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` y `GEMINI_API_KEY`. Sin `GEMINI_API_KEY`, el Genio responde con reglas por palabras clave.

> **Estado actual:** `backend/database.py` todavía usa la API REST de Supabase, que ya no existe. El servidor arranca y sirve `/health` y `/docs`, pero los endpoints que leen o escriben datos fallarán hasta que [#17](https://github.com/wame21/crave-app/issues/17) lo reemplace por PostgreSQL y [#16](https://github.com/wame21/crave-app/issues/16) agregue el esquema en `db/init/`.

## 3. App (Flutter)

```bash
flutter pub get
flutter run                        # o: flutter run -d chrome / -d linux
```

La URL del backend está en `lib/services/api_client.dart` (`baseUrl`). Por defecto es `http://10.0.2.2:8000/api`, que es como el emulador de Android llega al `localhost` de la máquina. Para web, escritorio o simulador de iOS, cámbiala a `http://localhost:8000/api`; en un teléfono físico, usa la IP de tu máquina en la red local. [#19](https://github.com/wame21/crave-app/issues/19) la vuelve configurable.

## Verificación

```bash
flutter analyze
flutter test
```
