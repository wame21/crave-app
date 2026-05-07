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
            // Sección Superior (Fondo gris con Stack para asegurar la X)
            Container(
              width: double.infinity,
              color: Colors.grey.shade200,
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Botón X clavado a la izquierda
                  Positioned(
                    left: 24,
                    top: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black, size: 24),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.pop(context); 
                        },
                      ),
                    ),
                  ),
                  
                  // Foto y Nombre centrados
                  Column(
                    children: [
                      Container(
                        width: 100, 
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                          color: Colors.yellow.shade200, 
                        ),
                        child: const Icon(Icons.person, size: 60, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
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
                    const Text(
                      'Mis favoritos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

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
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  // --- FUNCIÓN AYUDANTE --- //
  Widget _buildFavoriteItem(String name, Color bgColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Container(
          width: double.infinity,
          height: 130, 
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12), 
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