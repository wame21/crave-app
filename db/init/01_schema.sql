-- ============================================================================
-- Crave App — esquema de base de datos
--
-- Patrón "una base de datos por servicio" dentro de una sola instancia:
-- cada servicio es dueño de su propio esquema de Postgres y nadie más lee ni
-- escribe sus tablas. Entre esquemas NO hay claves foráneas; las referencias
-- a datos de otro servicio (id_owner, id_client, id_restaurant) son IDs
-- lógicos que se validan a través de los contratos (backend/contracts/).
--
-- Postgres ejecuta este archivo solo al crear el volumen. Para reaplicarlo:
--   docker compose down -v && docker compose up -d --wait
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ----------------------------------------------------------------------------
-- Servicio Identity
-- ----------------------------------------------------------------------------
CREATE SCHEMA identity;
COMMENT ON SCHEMA identity IS 'Servicio Identity: usuarios, credenciales y roles';

CREATE TABLE identity.users (
    id_user       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    profile_name  text        NOT NULL,
    email         text        NOT NULL UNIQUE,
    password_hash text        NOT NULL,  -- bcrypt ($2a$/$2b$)
    role          text        NOT NULL CHECK (role IN ('Client', 'Owner')),
    photo_url     text,
    created_at    timestamptz NOT NULL DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- Servicio Catalog
-- ----------------------------------------------------------------------------
CREATE SCHEMA catalog;
COMMENT ON SCHEMA catalog IS 'Servicio Catalog: restaurantes';

CREATE TABLE catalog.restaurants (
    id_restaurant  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_owner       bigint,               -- ID lógico de identity.users (sin FK)
    name           text          NOT NULL,
    description    text,
    food_type      text,
    price_range    text,                 -- "$", "$$", "$$$"
    address        text,
    latitude       double precision,
    longitude      double precision,
    phone          text,
    social_media   jsonb,                -- {"instagram": "@...", "facebook": "..."}
    opening_hours  text,
    overall_rating numeric(3,2)  NOT NULL DEFAULT 0
                   CHECK (overall_rating BETWEEN 0 AND 5),
    is_active      boolean       NOT NULL DEFAULT true,
    created_at     timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX restaurants_food_type_idx      ON catalog.restaurants (food_type);
CREATE INDEX restaurants_overall_rating_idx ON catalog.restaurants (overall_rating);
CREATE INDEX restaurants_id_owner_idx       ON catalog.restaurants (id_owner);


-- ----------------------------------------------------------------------------
-- Servicio Reviews
-- ----------------------------------------------------------------------------
CREATE SCHEMA reviews;
COMMENT ON SCHEMA reviews IS 'Servicio Reviews: reseñas de restaurantes';

CREATE TABLE reviews.reviews (
    id_review         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_client         bigint      NOT NULL,  -- ID lógico de identity.users
    id_restaurant     bigint      NOT NULL,  -- ID lógico de catalog.restaurants
    rating_food       smallint    NOT NULL CHECK (rating_food       BETWEEN 1 AND 5),
    rating_service    smallint    NOT NULL CHECK (rating_service    BETWEEN 1 AND 5),
    rating_atmosphere smallint    NOT NULL CHECK (rating_atmosphere BETWEEN 1 AND 5),
    comment           text,
    photo_gallery     text[]      NOT NULL DEFAULT '{}',
    status            text        NOT NULL DEFAULT 'Pending'
                      CHECK (status IN ('Pending', 'Approved', 'Rejected')),
    created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX reviews_id_restaurant_status_idx ON reviews.reviews (id_restaurant, status);
CREATE INDEX reviews_id_client_idx            ON reviews.reviews (id_client);


-- ----------------------------------------------------------------------------
-- Servicio Favorites
-- ----------------------------------------------------------------------------
CREATE SCHEMA favorites;
COMMENT ON SCHEMA favorites IS 'Servicio Favorites: restaurantes favoritos de cada cliente';

CREATE TABLE favorites.favorite_restaurants (
    id_favorite   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_client     bigint      NOT NULL,  -- ID lógico de identity.users
    id_restaurant bigint      NOT NULL,  -- ID lógico de catalog.restaurants
    created_at    timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id_client, id_restaurant)
);

COMMIT;
