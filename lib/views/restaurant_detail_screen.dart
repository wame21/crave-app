import 'package:flutter/material.dart';
import 'dart:async'; // Necesario para que los carruseles se muevan solos
import '../components/custom_bottom_nav.dart';
import 'all_reviews_screen.dart'; // Para ver todas las reseñas
import 'create_review_screen.dart'; // Para crear una nueva reseña

class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner Superior (Imagen + Botones X y Corazón)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade200, 
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Imagen de platillo aquí',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () {
                          Navigator.pop(context); 
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade200, 
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.black),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Cabecera (Logo, Nombre, Horario y Calificación)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.restaurant, color: Colors.teal),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'La cocina de Doña Licha',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Abierto ahora: Cierra a las 07:00 PM.',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.yellow.shade700, size: 24),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Botones Llamar y Cómo llegar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.black87),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Llamar', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.black87),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cómo llegar', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Información (Redes sociales y Horario Flotante)
                    const Text('Informacion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInfoIconButton(Icons.camera_alt_outlined, () {})),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInfoIconButton(Icons.facebook, () {})),
                        const SizedBox(width: 12),
                        // AQUÍ CONECTAMOS EL RELOJ AL DIÁLOGO FLOTANTE
                        Expanded(child: _buildInfoIconButton(Icons.watch_later_outlined, () {
                          _showScheduleDialog(context);
                        })),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 5. Menú (Carrusel Automático)
                    const Text('Menú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: GenericAutoCarousel(
                        items: [
                          {'text': 'Menú de Desayunos', 'color': Colors.orange.shade200},
                          {'text': 'Menú de Comidas', 'color': Colors.orange.shade300},
                          {'text': 'Bebidas y Postres', 'color': Colors.orange.shade400},
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 6. Fotos del Restaurante (Carrusel Automático)
                    const Text('Fotos del Restaurante', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: GenericAutoCarousel(
                        items: [
                          {'text': 'Foto Fachada', 'color': Colors.blueGrey.shade200},
                          {'text': 'Foto Interiores', 'color': Colors.blueGrey.shade300},
                          {'text': 'Foto Cocina', 'color': Colors.blueGrey.shade400},
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 7. Reseñas
                    const Text('Reseñas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    _buildReviewItem(
                      userName: 'Melisa Perez',
                      rating: '5.0',
                      reviewText: 'Nombre loco que buenas las tortas y el servicio bien rapido como a mi me gusta, recomendado 10/10.',
                      date: '02/02/2067',
                      avatarColor: Colors.blueGrey,
                    ),
                    _buildReviewItem(
                      userName: 'Pedro Sanchez',
                      rating: '5.0',
                      reviewText: 'Me gustaron mucho las tortas pero les pedi de favor que me las sirvieran sin cebolla loco, me dijieron que si y cuando me llego la tortona tenia cebolla loco estoy muy triste. Igual estaba buena la torta 10/10.',
                      date: '27/03/2067',
                      avatarColor: Colors.yellow.shade600,
                    ),

                    // 8. Botón Mas reseñas (Conecta a AllReviewsScreen)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AllReviewsScreen()),
                        );
                      },
                      child: Row(
                        children: const [
                          Text('Mas reseñas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black54),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 9. Botón para Hacer Reseña (Conecta a CreateReviewScreen)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateReviewScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.black87),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          '¿Qué te pareció este restaurante?',
                          style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  // --- FUNCIONES AYUDANTES --- //

  // Botones de información clickeables
  Widget _buildInfoIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87, size: 28),
      ),
    );
  }

  // Pantalla flotante del horario
  void _showScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Horario de Atención',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              _buildScheduleRow('Lunes', '08:00 AM - 07:00 PM'),
              _buildScheduleRow('Martes', '08:00 AM - 07:00 PM'),
              _buildScheduleRow('Miércoles', '08:00 AM - 07:00 PM'),
              _buildScheduleRow('Jueves', '08:00 AM - 07:00 PM'),
              _buildScheduleRow('Viernes', '08:00 AM - 09:00 PM'),
              _buildScheduleRow('Sábado', '09:00 AM - 10:00 PM'),
              _buildScheduleRow('Domingo', 'Cerrado', isClosed: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Cerrar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleRow(String day, String hours, {bool isClosed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isClosed ? FontWeight.bold : FontWeight.normal,
              color: isClosed ? Colors.red.shade400 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required String userName,
    required String rating,
    required String reviewText,
    required String date,
    required Color avatarColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
                border: Border.all(color: Colors.black54, width: 1),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow.shade700, size: 18),
                          const SizedBox(width: 2),
                          Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reviewText,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: Colors.black45, thickness: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}

// =======================================================
// WIDGET: Carrusel Genérico Reutilizable
// =======================================================
class GenericAutoCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const GenericAutoCarousel({super.key, required this.items});

  @override
  State<GenericAutoCarousel> createState() => _GenericAutoCarouselState();
}

class _GenericAutoCarouselState extends State<GenericAutoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) { 
      if (_currentPage < widget.items.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (int page) {
        setState(() {
          _currentPage = page;
        });
      },
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Container(
          decoration: BoxDecoration(
            color: item['color'],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            item['text'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
        );
      },
    );
  }
}