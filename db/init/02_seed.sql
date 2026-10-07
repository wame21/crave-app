-- ============================================================================
-- Crave App — datos de prueba
--
-- Usuarios (contraseña de todos: 123456)
--   ana@example.com     Client
--   carlos@example.com  Client
--   maria@example.com   Owner  → Taquería El Güero
--   jorge@example.com   Owner  → Pizzería Don Vito
--
-- Los demás restaurantes no tienen dueño registrado (id_owner NULL).
--
-- Los IDs se generan solos, en orden de antigüedad (ORDER BY days_ago DESC),
-- para que "más reciente por id" coincida con created_at. Las referencias
-- entre servicios se resuelven por clave natural (email, nombre del
-- restaurante) con LEFT JOIN: si una clave está mal escrita, el ID queda NULL,
-- viola el NOT NULL y la carga se aborta en lugar de descartar filas en
-- silencio.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- identity.users
-- crypt(..., gen_salt('bf')) genera hashes $2a$, compatibles con bcrypt.checkpw
-- ----------------------------------------------------------------------------
INSERT INTO identity.users (profile_name, email, password_hash, role, created_at)
SELECT v.profile_name, v.email, crypt('123456', gen_salt('bf')), v.role,
       now() - interval '90 days'
FROM (VALUES
    ('Ana López',       'ana@example.com',    'Client'),
    ('Carlos Ramírez',  'carlos@example.com', 'Client'),
    ('María González',  'maria@example.com',  'Owner'),
    ('Jorge Hernández', 'jorge@example.com',  'Owner')
) AS v(profile_name, email, role);


-- ----------------------------------------------------------------------------
-- catalog.restaurants — uno por cada categoría de CATEGORIES
-- (backend/routers/restaurants.py)
-- ----------------------------------------------------------------------------
INSERT INTO catalog.restaurants (
    id_owner, name, description, food_type, price_range, address,
    latitude, longitude, phone, social_media, opening_hours, created_at
)
SELECT u.id_user, v.name, v.description, v.food_type, v.price_range, v.address,
       v.latitude, v.longitude, v.phone, v.social_media::jsonb, v.opening_hours,
       now() - make_interval(days => v.days_ago)
FROM (VALUES
    ('maria@example.com', 'Taquería El Güero',
     'Tacos al pastor, suadero y campechanos con tortillas hechas a mano.',
     'Tacos', '$', 'Av. Álvaro Obregón 120, Roma Norte, CDMX',
     19.4194, -99.1617, '55 5264 1180',
     '{"instagram": "@taqueriaelguero", "facebook": "taqueriaelguero"}',
     'Lunes a domingo, 13:00 - 02:00', 80),

    ('jorge@example.com', 'Pizzería Don Vito',
     'Pizza al horno de leña con masa de fermentación lenta.',
     'Pizza', '$$', 'Calle Ámsterdam 45, Hipódromo Condesa, CDMX',
     19.4116, -99.1700, '55 5211 3344',
     '{"instagram": "@pizzeriadonvito", "facebook": "pizzeriadonvito"}',
     'Martes a domingo, 13:00 - 23:00', 75),

    (NULL, 'Sushi Koi',
     'Barra de sushi y nigiri con pescado fresco del día.',
     'Sushi', '$$$', 'Av. Presidente Masaryk 210, Polanco, CDMX',
     19.4319, -99.1925, '55 5280 7712',
     '{"instagram": "@sushikoi.mx"}',
     'Lunes a sábado, 13:30 - 22:30', 70),

    (NULL, 'Burger Barrio',
     'Hamburguesas smash, papas a la francesa y malteadas.',
     'Hamburguesas', '$$', 'Calle Orizaba 101, Roma Norte, CDMX',
     19.4180, -99.1590, '55 5574 2090',
     '{"instagram": "@burgerbarrio", "facebook": "burgerbarriomx"}',
     'Lunes a domingo, 12:00 - 23:00', 65),

    (NULL, 'Café Tostado',
     'Café de especialidad de Veracruz y Chiapas, pan dulce y patio interior.',
     'Café', '$', 'Calle Francisco Sosa 18, Coyoacán, CDMX',
     19.3490, -99.1680, '55 5658 4021',
     '{"instagram": "@cafetostado"}',
     'Lunes a domingo, 08:00 - 21:00', 60),

    (NULL, 'Alitas Fuego',
     'Alitas y boneless con doce salsas, de la BBQ a la habanero.',
     'Alitas', '$$', 'Av. Universidad 800, Del Valle, CDMX',
     19.3740, -99.1650, '55 5605 9987',
     NULL,
     'Lunes a domingo, 13:00 - 00:00', 50),

    (NULL, 'Trattoria Bella Napoli',
     'Pasta fresca hecha en casa y cocina del sur de Italia.',
     'Italiana', '$$$', 'Av. Michoacán 30, Condesa, CDMX',
     19.4110, -99.1720, '55 5286 6350',
     '{"instagram": "@bellanapoli.cdmx", "facebook": "trattoriabellanapoli"}',
     'Martes a domingo, 13:00 - 23:00', 45),

    (NULL, 'La Cocina de Doña Lupe',
     'Comida corrida, moles y guisados de olla como en casa.',
     'Mexicana', '$$', 'Calle Allende 15, Coyoacán, CDMX',
     19.3502, -99.1620, '55 5554 1276',
     '{"facebook": "lacocinadedonalupe"}',
     'Lunes a sábado, 09:00 - 18:00', 40),

    (NULL, 'Dragón Dorado',
     'Cocina cantonesa: dim sum, arroz frito y pato laqueado.',
     'China', '$$', 'Calle Dolores 25, Centro Histórico, CDMX',
     19.4330, -99.1420, '55 5512 8833',
     NULL,
     'Lunes a domingo, 11:00 - 22:00', 30),

    (NULL, 'Mariscos La Ola',
     'Cocteles, aguachiles y tostadas de mariscos estilo Sinaloa.',
     'Mariscos', '$$', 'Av. Insurgentes Sur 1500, Crédito Constructor, CDMX',
     19.3620, -99.1820, '55 5662 4410',
     '{"instagram": "@mariscoslaola"}',
     'Lunes a domingo, 11:00 - 19:00', 10)
) AS v(owner_email, name, description, food_type, price_range, address,
       latitude, longitude, phone, social_media, opening_hours, days_ago)
LEFT JOIN identity.users u ON u.email = v.owner_email
ORDER BY v.days_ago DESC;


-- ----------------------------------------------------------------------------
-- reviews.reviews
-- Mariscos La Ola queda sin reseñas, y la reseña pendiente de Dragón Dorado
-- no debe contar para su calificación.
-- ----------------------------------------------------------------------------
INSERT INTO reviews.reviews (
    id_client, id_restaurant, rating_food, rating_service, rating_atmosphere,
    comment, status, created_at
)
SELECT u.id_user, r.id_restaurant, v.rating_food, v.rating_service,
       v.rating_atmosphere, v.comment, v.status,
       now() - make_interval(days => v.days_ago)
FROM (VALUES
    ('ana@example.com',    'Taquería El Güero',      5, 4, 4,
     'Los tacos al pastor son de los mejores de la Roma. La salsa verde pica en serio.', 'Approved', 12),
    ('carlos@example.com', 'Taquería El Güero',      5, 5, 3,
     'Rápido y barato. El local es pequeño, pero vale la pena.', 'Approved', 5),
    ('ana@example.com',    'Pizzería Don Vito',      4, 4, 5,
     'Masa delgada y bien horneada. Muy buen ambiente para ir con amigos.', 'Approved', 20),
    ('carlos@example.com', 'Pizzería Don Vito',      3, 4, 4,
     'La de pepperoni estaba bien, aunque tardaron un poco en traerla.', 'Approved', 3),
    ('carlos@example.com', 'Sushi Koi',              5, 5, 5,
     'El nigiri de salmón se deshace en la boca. Caro, pero lo vale.', 'Approved', 15),
    ('ana@example.com',    'Burger Barrio',          4, 3, 4,
     'Hamburguesa jugosa y papas crujientes. El servicio puede mejorar.', 'Approved', 9),
    ('ana@example.com',    'Café Tostado',           5, 5, 5,
     'Café excelente y un patio muy tranquilo para trabajar.', 'Approved', 2),
    ('carlos@example.com', 'Café Tostado',           4, 5, 5,
     'Buen capuchino y pan dulce recién hecho.', 'Approved', 7),
    ('carlos@example.com', 'Alitas Fuego',           4, 3, 3,
     'Las alitas BBQ están muy buenas; el lugar es algo ruidoso.', 'Approved', 11),
    ('ana@example.com',    'Trattoria Bella Napoli', 5, 4, 5,
     'La pasta fresca es increíble. Ideal para una cena especial.', 'Approved', 25),
    ('carlos@example.com', 'La Cocina de Doña Lupe', 5, 5, 4,
     'El mole sabe a casa y las porciones son generosas.', 'Approved', 6),
    ('ana@example.com',    'Dragón Dorado',          3, 3, 2,
     'La comida es correcta, pero el local necesita mantenimiento.', 'Approved', 14),
    ('carlos@example.com', 'Dragón Dorado',          2, 2, 2,
     'Esperé 40 minutos por mi pedido.', 'Pending', 1)
) AS v(client_email, restaurant_name, rating_food, rating_service,
       rating_atmosphere, comment, status, days_ago)
LEFT JOIN identity.users u ON u.email = v.client_email
LEFT JOIN catalog.restaurants r ON r.name = v.restaurant_name
ORDER BY v.days_ago DESC;


-- ----------------------------------------------------------------------------
-- favorites.favorite_restaurants
-- ----------------------------------------------------------------------------
INSERT INTO favorites.favorite_restaurants (id_client, id_restaurant, created_at)
SELECT u.id_user, r.id_restaurant, now() - make_interval(days => v.days_ago)
FROM (VALUES
    ('ana@example.com',    'Taquería El Güero',      10),
    ('ana@example.com',    'Café Tostado',            2),
    ('ana@example.com',    'Trattoria Bella Napoli', 24),
    ('carlos@example.com', 'Sushi Koi',              14),
    ('carlos@example.com', 'La Cocina de Doña Lupe',  6)
) AS v(client_email, restaurant_name, days_ago)
LEFT JOIN identity.users u ON u.email = v.client_email
LEFT JOIN catalog.restaurants r ON r.name = v.restaurant_name
ORDER BY v.days_ago DESC;


-- ----------------------------------------------------------------------------
-- overall_rating = promedio de las reseñas aprobadas, con la misma fórmula que
-- el servicio de reseñas: media de (comida + servicio + ambiente) / 3,
-- redondeada a 2 decimales. Sin reseñas aprobadas se queda en 0.
-- ----------------------------------------------------------------------------
UPDATE catalog.restaurants AS r
SET overall_rating = s.rating
FROM (
    SELECT id_restaurant,
           round(avg((rating_food + rating_service + rating_atmosphere) / 3.0), 2) AS rating
    FROM reviews.reviews
    WHERE status = 'Approved'
    GROUP BY id_restaurant
) AS s
WHERE r.id_restaurant = s.id_restaurant;

COMMIT;
