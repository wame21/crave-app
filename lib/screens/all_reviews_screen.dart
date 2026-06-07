import 'package:flutter/material.dart';

class AllReviewsScreen extends StatelessWidget {
  const AllReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Usamos un AppBar sencillo solo para la flecha de regresar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabecera Central
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Todas las reseñas de:',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.restaurant, color: Colors.teal, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'La cocina de Doña Licha',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        // Estrella y Calificación
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.yellow.shade700, size: 20),
                              const SizedBox(width: 4),
                              const Text(
                                '4.8',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. Título de la sección
              const Text(
                'Reseñas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 20),

              // 3. Lista de Reseñas Detalladas
              
              // Reseña 1 (Con imagen)
              _buildDetailedReviewItem(
                userName: 'Melisa Perez',
                date: '02/02/2067',
                reviewText: 'Nombre loco que buenas las tortas y el servicio bien rapido como a mi me gusta, recomendado 10/10.',
                avatarColor: Colors.blueGrey,
                hasImage: true, // ¡Esta tiene foto!
                servicio: '5.0',
                comida: '5.0',
                ambiente: '5.0',
              ),

              // Reseña 2 (Sin imagen)
              _buildDetailedReviewItem(
                userName: 'Pedro Sanchez',
                date: '27/03/2067',
                reviewText: 'Me gustaron mucho las tortas pero les pedi de favor que me las sirvieran sin cebolla loco, me dijieron que si y cuando me llego la tortona tenia cebolla loco estoy muy triste. Igual estaba buena la torta 10/10.',
                avatarColor: Colors.yellow.shade600,
                hasImage: false, // Esta no tiene foto
                servicio: '5.0',
                comida: '5.0',
                ambiente: '5.0',
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNCIONES AYUDANTES --- //

  Widget _buildDetailedReviewItem({
    required String userName,
    required String date,
    required String reviewText,
    required Color avatarColor,
    required bool hasImage,
    required String servicio,
    required String comida,
    required String ambiente,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Avatar, Nombre y Fecha
        Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
                border: Border.all(color: Colors.black54, width: 1),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              userName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Spacer(), // Empuja la fecha hasta la derecha
            Text(
              date,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fila 2: Texto de la reseña
        Text(
          reviewText,
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // Fila 3: Imagen (Solo se dibuja si hasImage es true)
        if (hasImage) ...[
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade100, // Color de placeholder
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('Foto subida por el usuario', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          const SizedBox(height: 16),
        ],

        // Fila 4: Calificaciones Detalladas (Servicio, Comida, Ambiente)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniRating('Servicio', servicio),
            const SizedBox(width: 16),
            _buildMiniRating('Comida', comida),
            const SizedBox(width: 16),
            _buildMiniRating('Ambiente', ambiente),
          ],
        ),
        const SizedBox(height: 16),

        // Línea divisoria
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  // Pequeño widget para "Servicio ⭐5.0"
  Widget _buildMiniRating(String label, String rating) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(width: 4),
        Icon(Icons.star, color: Colors.yellow.shade700, size: 16),
        Text(
          rating,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }
}