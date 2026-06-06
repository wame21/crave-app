import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'login_screen.dart';
import 'restaurant_detail_screen.dart'; // Para ir a ver su propio restaurante
import 'edit_restaurant_screen.dart';

class RestaurantProfileScreen extends StatelessWidget {
  const RestaurantProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Sección Superior (Banner + Logo + Nombre)
            Container(
              color: Colors
                  .grey
                  .shade200, // El fondo gris clarito de abajo del banner
              child: Column(
                children: [
                  // Stack para encimar el logo sobre el banner
                  Stack(
                    clipBehavior:
                        Clip.none, // Permite que el logo se salga del stack
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Banner del restaurante
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors
                              .pink
                              .shade200, // Placeholder del banner de Doña Licha
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Banner del Restaurante',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Logo circular encimado (bajado 50 pixeles)
                      Positioned(
                        bottom: -50,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.shade100,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ), // Borde blanco para resaltar
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 60,
                  ), // Espacio para que el logo no tape el texto
                  // Nombre del restaurante
                  const Text(
                    'La cocina de Doña Licha',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ), // Espacio antes de terminar el fondo gris
                ],
              ),
            ),

            // 2. Sección Inferior (Botones sobre fondo blanco)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // Botón: Mi Restaurante
                    _buildProfileButton('Mi Restaurante', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // ---> AQUÍ ESTÁ EL CAMBIO W <---
                          builder: (context) => const RestaurantDetailScreen(
                            restaurantId: '2', // ID temporal de prueba
                            restaurantName:
                                'La cocina de Doña Licha', // Nombre de prueba
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Botón: Editar Restaurante
                    _buildProfileButton('Editar Restaurante', () {
                      // Aquí irá la futura pantalla de editar restaurante
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditRestaurantScreen(),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Botón: Mis Favoritos
                    _buildProfileButton('Mis Favoritos', () {
                      // Puedes reutilizar la pantalla de favorites_screen.dart si quieres
                    }),
                    const SizedBox(height: 16),

                    // Botón: Reseñas Publicadas
                    _buildProfileButton('Reseñas Publicadas', () {
                      // Puedes reutilizar la pantalla de my_reviews_screen.dart
                    }),
                    const SizedBox(height: 40),

                    // Botón: Cerrar Sesión (Destructivo)
                    _buildProfileButton('Cerrar sesión', () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // La barra inferior seleccionando el índice 3 (Perfil)
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  // --- FUNCIÓN AYUDANTE --- //
  Widget _buildProfileButton(String text, VoidCallback onPressed) {
    bool isLogout = text == 'Cerrar sesión';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: isLogout ? Colors.red.shade400 : Colors.black87,
            width: isLogout ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isLogout ? Colors.red.shade400 : Colors.black,
            fontSize: 16,
            fontWeight: isLogout ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
