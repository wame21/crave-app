# 🍽️ Crave App — Backend API

Backend construido con **FastAPI + Python** conectado a **Supabase (PostgreSQL)**.

## 📁 Estructura del proyecto

```
backend/
├── main.py                  # Punto de entrada FastAPI
├── config.py                # Configuración y variables de entorno
├── database.py              # Cliente Supabase compartido
├── requirements.txt         # Dependencias Python
├── .env                     # Variables de entorno (NO subir a git)
├── routers/
│   ├── auth.py              # Login y registro
│   ├── users.py             # Perfil de usuario
│   ├── restaurants.py       # Restaurantes (CRUD + búsqueda + home)
│   ├── reviews.py           # Reseñas
│   ├── favorites.py         # Favoritos
│   └── genie.py             # Genio de los antojos (IA)
├── schemas/
│   ├── auth.py              # Modelos Pydantic para auth
│   ├── user.py              # Modelos para usuarios
│   ├── restaurant.py        # Modelos para restaurantes
│   ├── review.py            # Modelos para reseñas
│   └── favorite.py          # Modelos para favoritos
└── utils/
    ├── auth.py              # JWT helpers
    └── password.py          # Hashing de contraseñas
```

## ⚙️ Instalación y ejecución

### 1. Crear entorno virtual e instalar dependencias

```bash
cd backend/
python3 -m venv venv
source venv/bin/activate        # Linux/Mac
# venv\Scripts\activate.bat    # Windows

pip install -r requirements.txt
```

### 2. Configurar variables de entorno

Edita el archivo `.env` con tus credenciales:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_KEY=tu_api_key
JWT_SECRET_KEY=una-clave-secreta-muy-larga
GEMINI_API_KEY=tu_gemini_api_key   # Opcional
```

### 3. Iniciar el servidor

```bash
source venv/bin/activate
uvicorn main:app --reload --port 8000
```

El servidor estará disponible en: **http://localhost:8000**

## 📖 Documentación interactiva

Una vez corriendo el servidor, accede a:

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

## 🔐 Autenticación

Los endpoints protegidos requieren un JWT en el header:

```
Authorization: Bearer <token>
```

Obtén tu token haciendo `POST /api/auth/login`.

## 📡 Endpoints principales

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/auth/login` | ❌ | Iniciar sesión |
| POST | `/api/auth/register/client` | ❌ | Registrar cliente |
| POST | `/api/auth/register/owner` | ❌ | Registrar dueño + restaurante |
| GET | `/api/users/me` | ✅ | Mi perfil |
| PUT | `/api/users/me` | ✅ | Actualizar perfil |
| GET | `/api/restaurants/home` | ❌ | Datos del Home |
| GET | `/api/restaurants/` | ❌ | Buscar restaurantes |
| GET | `/api/restaurants/{id}` | ❌ | Detalle restaurante |
| PUT | `/api/restaurants/{id}` | ✅ Owner | Editar restaurante |
| GET | `/api/reviews/restaurant/{id}` | ❌ | Reseñas de restaurante |
| GET | `/api/reviews/me` | ✅ | Mis reseñas |
| POST | `/api/reviews/` | ✅ Client | Crear reseña |
| DELETE | `/api/reviews/{id}` | ✅ | Eliminar reseña |
| GET | `/api/favorites/` | ✅ | Mis favoritos |
| POST | `/api/favorites/{id}` | ✅ | Agregar favorito |
| DELETE | `/api/favorites/{id}` | ✅ | Quitar favorito |
| POST | `/api/genie/chat` | ✅ | Chat con el Genio IA |

## 🧞 Genio de los Antojos (IA)

El endpoint `/api/genie/chat` funciona de dos modos:

1. **Con Gemini API key:** Usa Google Gemini 1.5 Flash para respuestas naturales
2. **Sin API key:** Usa lógica de palabras clave para recomendar restaurantes de la BD

Para habilitar Gemini, obtén tu API key en https://aistudio.google.com y agrégala al `.env`.

## 🔄 Ejemplo de flujo completo

```bash
# 1. Registrar usuario
curl -X POST http://localhost:8000/api/auth/register/client \
  -H "Content-Type: application/json" \
  -d '{"profile_name":"Juan","email":"juan@example.com","password":"123456","confirm_password":"123456"}'

# 2. Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"juan@example.com","password":"123456"}'

# 3. Usar el token retornado en endpoints protegidos
curl -X GET http://localhost:8000/api/users/me \
  -H "Authorization: Bearer <tu_token>"
```
