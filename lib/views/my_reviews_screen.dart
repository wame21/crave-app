import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sección Superior (Fondo gris clarito con el botón X)
            Container(
              width: double.infinity,
              color: Colors.grey.shade200,
              padding: const EdgeInsets.only(top: 16, bottom: 20, left: 24, right: 24),
              child: Column(
                children: [
                  // Botón X alineado a la izquierda
                  Align(
                    alignment: Alignment.topLeft,
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
                          Navigator.pop(context); // Regresa al perfil
                        },
                      ),
                    ),
                  ),

                  // Foto de perfil
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

            // Sección Inferior (Lista de Reseñas)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Mis reseñas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildReviewItem(
                      restaurantName: 'La cocina de doña licha',
                      userName: 'Pedro Sanchez',
                      rating: '5.0',
                      reviewText: 'Me gustaron mucho las tortas pero les pedi de favor que me las sirvieran sin cebolla loco, me dijieron que si y cuando me llego la tortona tenia cebolla loco estoy muy triste. Igual estaba buena la torta 10/10.',
                      date: '27/03/2067',
                    ),
                    
                    _buildReviewItem(
                      restaurantName: 'Caffenio',
                      userName: 'Pedro Sanchez',
                      rating: '5.0',
                      reviewText: 'Buenos, rapidos y baratos. Recominedo el frape de oreo. :D',
                      date: '12/04/2067',
                    ),
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
  Widget _buildReviewItem({
    required String restaurantName,
    required String userName,
    required String rating,
    required String reviewText,
    required String date,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              restaurantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
                color: Colors.yellow.shade200,
              ),
              child: const Icon(Icons.person, size: 28, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow.shade700, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    reviewText,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}