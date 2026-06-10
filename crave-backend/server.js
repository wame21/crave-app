const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const multer = require('multer'); 

const app = express();
app.use(cors());
app.use(express.json()); 

const upload = multer({ storage: multer.memoryStorage() }); 

// Tus llaves 
const supabaseUrl = 'https://kwzbjpcakuiyveothbcr.supabase.co';
const supabaseKey = 'sb_secret_PfUJcpvFJ3gSe2k_GXbfAw_Fynpp0PI';

const supabase = createClient(supabaseUrl, supabaseKey);

// ==========================================
// RUTAS DE AUTENTICACIÓN
// ==========================================
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single();

    if (!user) {
      return res.status(401).json({ error: "Cuenta inexistente. ¡Regístrate primero!" });
    }
    if (user.password_hash !== password) {
      return res.status(401).json({ error: "Contraseña incorrecta." });
    }
    res.json({ message: "¡Bienvenido!", user: user });
  } catch (error) {
    console.error(error.message);
    res.status(500).json({ error: "Hubo un problema en el servidor." });
  }
});

app.post('/api/register', async (req, res) => {
  try {
    const { profile_name, email, password, role } = req.body;
    const { data, error } = await supabase
      .from('users')
      .insert([{ profile_name, email, password_hash: password, role }])
      .select();

    if (error) {
      if (error.code === '23505') return res.status(400).json({ error: "¡Correo ya registrado!" });
      throw error;
    }
    res.json({ message: "¡Cuenta creada!", user: data[0] });
  } catch (error) {
    console.error("Error en registro:", error.message);
    res.status(500).json({ error: "Hubo un problema al crear la cuenta." });
  }
});

// ==========================================
// RUTA PARA OBTENER PERFIL
// ==========================================
app.get('/api/user/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { data: user, error } = await supabase
      .from('users')
      .select('profile_name, email, role, photo_url')
      .eq('id_user', id)
      .single();

    if (error) throw error;
    res.json(user);
  } catch (error) {
    console.error("Error al obtener perfil:", error.message);
    res.status(500).json({ error: "No se pudo obtener el perfil" });
  }
});

// ==========================================
// RUTA PARA SUBIR FOTO DE PERFIL
// ==========================================
app.post('/api/user/:id/photo', upload.single('photo'), async (req, res) => {
  try {
    const { id } = req.params;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: "No enviaste ninguna foto w" });
    }

    const fileName = `perfil_${id}_${Date.now()}.${file.mimetype.split('/')[1]}`;

    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
      });

    if (uploadError) throw uploadError;

    const { data: publicUrlData } = supabase.storage
      .from('avatars')
      .getPublicUrl(fileName);
      
    const photoUrl = publicUrlData.publicUrl;

    const { error: updateError } = await supabase
      .from('users')
      .update({ photo_url: photoUrl })
      .eq('id_user', id);

    if (updateError) throw updateError;

    res.json({ message: "¡Foto actualizada con éxito!", photo_url: photoUrl });
  } catch (error) {
    console.error("Error al subir foto:", error.message);
    res.status(500).json({ error: "Hubo bronca al subir la imagen" });
  }
});

// ==========================================
// RUTA DE RESTAURANTES
// ==========================================
app.get('/api/restaurants', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select('*');

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error("Error al obtener restaurantes:", error.message);
    res.status(500).json({ error: "No se pudieron obtener los restaurantes" });
  }
});

// ==========================================
// RUTAS DE FAVORITOS (CONECTADAS AL CIEN)
// ==========================================

// 1. Traer todos los favoritos de un cliente
app.get('/api/favorite_restaurants/:id_client', async (req, res) => {
  try {
    const { id_client } = req.params;
    const { data, error } = await supabase
      .from('favorite_restaurants') // <-- La tabla correcta de tu SQL
      .select('*, restaurants(*)')
      .eq('id_client', id_client);  // <-- Tu columna se llama id_client, no id_user

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error("Error en favoritos:", error.message);
    res.status(500).json({ error: "No se pudieron cargar los favoritos" });
  }
});

// 2. Agregar a favoritos
app.post('/api/favorite_restaurants', async (req, res) => {
  try {
    const { id_client, id_restaurant } = req.body; 
    const { error } = await supabase
      .from('favorite_restaurants') // <-- La tabla correcta
      .insert([{ id_client: parseInt(id_client, 10), id_restaurant: parseInt(id_restaurant, 10) }]);
      
    if (error) {
      console.error("Error de Supabase al agregar favorito:", error.message);
      throw error;
    }
    res.json({ message: '¡Agregado a favoritos w!' });
  } catch (error) {
    res.status(500).json({ error: 'Error al agregar favorito' });
  }
});

// 3. Quitar de favoritos
app.delete('/api/favorite_restaurants', async (req, res) => {
  try {
    const { id_client, id_restaurant } = req.body;
    const { error } = await supabase
      .from('favorite_restaurants')
      .delete()
      .match({ id_client: parseInt(id_client, 10), id_restaurant: parseInt(id_restaurant, 10) }); // <-- Esto ya estaba bien
      
    if (error) throw error;
    res.json({ message: '¡Eliminado de favoritos w!' });
  } catch (error) {
    res.status(500).json({ error: 'Error al quitar favorito' });
  }
});

// 4. Checar si un restaurante específico es favorito
app.get('/api/favorite_restaurants/check/:clientId/:restaurantId', async (req, res) => {
  try {
    const { clientId, restaurantId } = req.params;
    const { data, error } = await supabase
      .from('favorite_restaurants')
      .select('*')
      .eq('id_client', parseInt(clientId, 10)) // <-- Corregido para que embone con tu SQL
      .eq('id_restaurant', parseInt(restaurantId, 10)); 
      
    if (error) throw error;
    res.json({ isFavorite: data.length > 0 });
  } catch (error) {
    res.status(500).json({ error: 'Error al verificar favorito' });
  }
});

// ==========================================
// RUTAS DE RESEÑAS (CORREGIDAS)
// ==========================================
app.post('/api/reviews', async (req, res) => {
  try {
    const { id_user, id_restaurant, rating_food, rating_service, rating_atmosphere, comment } = req.body;
    
    const { error } = await supabase
      .from('reviews')
      // AQUI ESTÁ EL FIX: Transformamos id_user a id_client para que Supabase lo acepte
      .insert([{ 
        id_client: parseInt(id_user, 10), 
        id_restaurant: parseInt(id_restaurant, 10), 
        rating_food, 
        rating_service, 
        rating_atmosphere, 
        comment 
      }]); 
      
    if (error) {
      console.error("Error de Supabase al subir reseña:", error.message);
      throw error;
    }
    res.json({ message: '¡Reseña guardada al cien!' });
  } catch (error) {
    res.status(500).json({ error: 'Error al guardar reseña' });
  }
});

// Traer reseñas de un restaurante
app.get('/api/reviews/restaurant/:restaurantId', async (req, res) => {
  try {
    const { restaurantId } = req.params;
    const { data, error } = await supabase
      .from('reviews')
      .select('*, users(profile_name, photo_url)')
      .eq('id_restaurant', parseInt(restaurantId, 10))
      .order('created_at', { ascending: false });

    if (error) throw error;

    const reviewsWithRating = data.map(r => {
      const avg = (r.rating_food + r.rating_service + r.rating_atmosphere) / 3;
      return {
        ...r,
        overall_rating: avg.toFixed(1)
      };
    });

    res.json(reviewsWithRating);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener reseñas' });
  }
});

// Traer reseñas hechas por un usuario
app.get('/api/reviews/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { data, error } = await supabase
      .from('reviews')
      .select('*, restaurants(name)')
      .eq('id_client', parseInt(userId, 10))
      .order('created_at', { ascending: false });

    if (error) throw error;

    const reviewsWithRating = data.map(r => {
      const avg = (r.rating_food + r.rating_service + r.rating_atmosphere) / 3;
      return {
        ...r,
        overall_rating: avg.toFixed(1)
      };
    });

    res.json(reviewsWithRating);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener tus reseñas' });
  }
});

// ==========================================
// RUTA TEMPORAL PARA CREAR RESTAURANTES
// ==========================================
app.get('/api/seed-restaurants', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .insert([
        {
          name: 'El Asador de Guasave',
          description: 'Cortes finos y mariscos al carbón. Ideal para una buena cena loco.',
          food_type: 'Carnes y Mariscos',
          price_range: '$$$',
          is_active: true,
          overall_rating: 4.9
        },
        {
          name: 'Taquería La Desvelada',
          description: 'Tacos de adobada y asada 24/7. Te salvan la vida después de la fiesta.',
          food_type: 'Mexicana',
          price_range: '$',
          is_active: true,
          overall_rating: 4.5
        }
      ])
      .select();

    if (error) throw error;
    res.json({ message: "¡Restaurantes de prueba listos w!", data });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Hubo bronca al insertarlos" });
  }
});

// =====================================
// EL MOTOR DE ARRANQUE (Al mero final)
// =====================================
app.listen(3000, '0.0.0.0', () => {
  console.log("¡Servidor jalando al cien en el puerto 3000 w!");
});
// --- RUTAS DEL PANEL DE RESTAURANTE ---

// 1. Traer los datos del restaurante usando el ID del dueño
app.get('/api/restaurants/owner/:id_client', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select('*')
      // AQUÍ ESTÁ LA MAGIA: Cambiamos id_user por id_owner w
      .eq('id_owner', req.params.id_client) 
      .single();

    if (error && error.code !== 'PGRST116') {
      console.error("¡AY WEY! Error al traer restaurante:", error);
      throw error;
    }
    
    res.json(data || {});
  } catch (error) {
    res.status(500).json({ error: 'Error al cargar los datos del restaurante w' });
  }
});

// 2. Guardar los cambios (Crea uno nuevo si no existe, o actualiza si ya existe)
app.post('/api/restaurants/upsert', async (req, res) => {
  try {
    const { id_user, name, description, address, food_type } = req.body;

    // Buscamos si ya existe
    const { data: existing } = await supabase
      .from('restaurants')
      .select('id_restaurant')
      .eq('id_owner', id_user) // <-- CORREGIDO AQUÍ
      .single();

    let result;
    if (existing) {
      result = await supabase
        .from('restaurants')
        .update({ name, description, address, food_type })
        .eq('id_restaurant', existing.id_restaurant);
    } else {
      // Si es nuevo, insertamos usando id_owner
      result = await supabase
        .from('restaurants')
        .insert([{ id_owner: id_user, name, description, address, food_type }]); // <-- CORREGIDO AQUÍ
    }

    if (result.error) {
      console.error("¡AY WEY! Error al hacer upsert:", result.error);
      throw result.error;
    }
    
    res.json({ message: '¡Datos guardados al cien!' });
  } catch (error) {
    res.status(500).json({ error: 'Error al guardar los cambios w' });
  }
});