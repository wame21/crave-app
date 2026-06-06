import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart'; // <-- Aseguramos la importación de tus servicios
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'my_reviews_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Función auxiliar para traer los datos del usuario usando su gafete de ID
  Future<Map<String, dynamic>?> _cargarDatosPerfil() async {
    final userId = await ApiService.obtenerUsuarioId();
    print('DEBUG EN PANTALLA: El ID recuperado de la memoria es: $userId');
    if (userId != null) {
      return await ApiService.obtenerPerfil(userId);
    }
    print('DEBUG EN PANTALLA: Ojo loco, el userId vino NULL de la memoria');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _cargarDatosPerfil(),
          builder: (context, snapshot) {
            // 1. Mientras la tubería está jalando los datos de Supabase, mostramos una ruedita
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            // 2. Si algo falló o no encontró al usuario, avisa en pantalla
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return const Center(
                child: Text(
                  'No se pudieron cargar los datos de tu perfil w.',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }

            // 3. Si todo sale al cien, extraemos los datos reales
            final datosUsuario = snapshot.data!;
            final nombreReal =
                datosUsuario['profile_name'] ?? 'Usuario sin nombre';

            return Column(
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
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ¡Adiós Pedro Sánchez! Hola nombre real de la BD
                      Text(
                        nombreReal,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        _buildProfileButton('Mis Favoritos', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        _buildProfileButton('Reseñas Publicadas', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyReviewsScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 40),

                        // Botón de Cerrar Sesión actualizado
                        _buildProfileButton('Cerrar sesión', () async {
                          // Borramos el ID de la memoria para limpiar la sesión
                          await ApiService.cerrarSesion();

                          if (!context.mounted) return;

                          // Te saca al login limpiando el historial
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
            );
          },
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
            color: text == 'Cerrar sesión'
                ? Colors.red.shade400
                : Colors.black87,
            width: text == 'Cerrar sesión' ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: text == 'Cerrar sesión' ? Colors.red.shade400 : Colors.black,
            fontSize: 16,
            fontWeight: text == 'Cerrar sesión'
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
