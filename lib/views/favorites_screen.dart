import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Column(
                children: [
                  // Foto de perfil (un poco más pequeña que en la pantalla principal)
                  Container(
                    width: 100, 
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                      color: Colors.yellow.shade200, // Color temporal
                    ),
                    child: const Icon(Icons.person, size: 60, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre del usuario
                  const Text(
                    'Pedro Sanchez',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Sección Inferior (Lista de Favoritos)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Título de la sección
                    const Text(
                      'Mis favoritos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjetas de Restaurantes Favoritos
                    _buildFavoriteItem('La cocina de doña Licha', Colors.teal.shade100, Colors.teal),
                    const SizedBox(height: 24),
                    _buildFavoriteItem('Caffenio', Colors.brown.shade100, Colors.brown),
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
  // Crea el texto con la flechita y el banner del restaurante
  Widget _buildFavoriteItem(String name, Color bgColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre y flecha
        Row(
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
          ],
        ),
        const SizedBox(height: 12),
        
        // Banner del restaurante
        Container(
          width: double.infinity,
          height: 130, // Altura del banner
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12), // Bordes redondeados
          ),
          alignment: Alignment.center,
          child: Text(
            '$name\n(Banner aquí)',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ],
    );
  }
}