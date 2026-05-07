import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Barra de búsqueda
              TextField(
                autofocus:
                    true, // Hace que el teclado se abra automáticamente al entrar aquí
                decoration: InputDecoration(
                  hintText: 'Buscar',
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Categorías
              Row(
                children: const [
                  Text(
                    'Categorías',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.black54,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 95,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryItem(Icons.bento, 'Sushi'),
                    _buildCategoryItem(Icons.local_pizza, 'Pizza'),
                    _buildCategoryItem(Icons.local_cafe, 'Café'),
                    _buildCategoryItem(Icons.fastfood, 'Alitas'),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Últimos buscados
              const Text(
                'Ultimos buscados:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Lista expandida para los restaurantes recientes
              Expanded(
                child: ListView(
                  children: [
                    _buildRecentSearchItem(
                      'La cocina de Doña Licha',
                      '4.8',
                      Colors.teal.shade100,
                      Colors.teal,
                    ),
                    _buildRecentSearchItem(
                      'Caffenio',
                      '4.6',
                      Colors.brown.shade100,
                      Colors.brown,
                    ),
                    _buildRecentSearchItem(
                      'Burger King',
                      '4.2',
                      Colors.orange.shade100,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Menú inferior (Índice 1 seleccionado = Buscar)
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  // --- FUNCIONES AYUDANTES --- //

  // Círculos de categorías "gorditos" (Reutilizados del Home)
  Widget _buildCategoryItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2.5),
              color: Colors.white,
            ),
            child: Icon(icon, size: 32, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Filas de restaurantes recientes
  Widget _buildRecentSearchItem(
    String name,
    String rating,
    Color bgColor,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Simulación del logo circular del restaurante
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              name[0], // Pone la primera letra del nombre como logo
              style: TextStyle(
                color: iconColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Nombre del restaurante
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          // Estrella y calificación
          Icon(Icons.star, color: Colors.yellow.shade700, size: 24),
          const SizedBox(width: 4),
          Text(
            rating,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
