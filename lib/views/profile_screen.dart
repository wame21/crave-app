import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'my_reviews_screen.dart';
import 'login_screen.dart'; // Importamos la pantalla de Login

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sección Superior (Fondo gris clarito)
            Container(
              width: double.infinity, 
              color: Colors.grey.shade200, 
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              child: Column(
                children: [
                  // Foto de perfil
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                      color: Colors.yellow.shade200, 
                    ),
                    child: const Icon(Icons.person, size: 80, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nombre del usuario
                  const Text(
                    'Pedro Sanchez',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // Sección Inferior (Botones sobre fondo blanco)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Botones de opciones
                    _buildProfileButton('Editar Perfil', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    }),
                    const SizedBox(height: 16),
                    
                    _buildProfileButton('Mis Favoritos', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                      );
                    }),
                    const SizedBox(height: 16),
                    
                    _buildProfileButton('Reseñas Publicadas', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyReviewsScreen()),
                      );
                    }),
                    const SizedBox(height: 40), // Un espacio un poco más grande para separar el logout

                    // Botón de Cerrar Sesión
                    _buildProfileButton('Cerrar sesión', () {
                      // pushAndRemoveUntil borra el historial de navegación para que no puedan regresar con la flecha de atrás
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
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
    return SizedBox(
      width: double.infinity, 
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white, 
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            // Si el botón es de cerrar sesión, lo pintamos de rojo para que resalte
            color: text == 'Cerrar sesión' ? Colors.red.shade400 : Colors.black87,
            width: text == 'Cerrar sesión' ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            // El texto también rojo si es cerrar sesión
            color: text == 'Cerrar sesión' ? Colors.red.shade400 : Colors.black,
            fontSize: 16,
            fontWeight: text == 'Cerrar sesión' ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}