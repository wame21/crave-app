-- ============================================================================
-- Crave App — categorías del catálogo (servicio Catalog)
--
-- Antes estaban fijas en el código del router de restaurantes. Ahora son datos
-- del esquema `catalog`, y el food_type de cada restaurante debe ser una de
-- ellas. Se ejecuta después de 01_schema.sql y 02_seed.sql.
-- ============================================================================

BEGIN;

CREATE TABLE catalog.categories (
    name     text     PRIMARY KEY,
    position smallint NOT NULL UNIQUE   -- orden en que las muestra la app
);

INSERT INTO catalog.categories (name, position) VALUES
    ('Tacos',         1),
    ('Pizza',         2),
    ('Sushi',         3),
    ('Hamburguesas',  4),
    ('Café',          5),
    ('Alitas',        6),
    ('Italiana',      7),
    ('Mexicana',      8),
    ('China',         9),
    ('Mariscos',     10);

-- Dentro del mismo esquema (mismo servicio) sí puede haber claves foráneas.
ALTER TABLE catalog.restaurants
    ADD CONSTRAINT restaurants_food_type_fkey
    FOREIGN KEY (food_type) REFERENCES catalog.categories (name)
    ON UPDATE CASCADE;

COMMIT;
