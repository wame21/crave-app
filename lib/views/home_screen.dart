import 'package:flutter/material.dart';
import 'dart:async'; // Para el carrusel que se mueve solo

// Importamos todas las pantallas a las que podemos navegar desde aquí
import '../components/custom_bottom_nav.dart';
import 'search_screen.dart';
import 'restaurant_detail_screen.dart';
import 'favorites_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculamos el tamaño de la pantalla para que quepan 2 tarjetas y un cachito
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth * 0.42;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Barra de búsqueda (Funciona como un botón gigante)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const SearchScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: TextField(
                    enabled: false, // Deshabilitado para que no abra el teclado aquí
                    decoration: InputDecoration(
                      hintText: 'Buscar',
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Botón de Favoritos (Con su margen corregido)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                                          Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                    },
                    icon: const Icon(Icons.favorite_border, color: Colors.black),
                    label: const Text(
                      'Favoritos',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Banner Destacados del día (Carrusel Automático)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Destacados\ndel día',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: SizedBox(
                        height: 90,
                        child: AutoCarouselDestacados(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 4. Categorías "Gorditas"
                _buildSectionTitle('Categorías'),
                const SizedBox(height: 12),
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

                // 5. Mejor valorados
                _buildSectionTitle('Mejor valorados'),
                const SizedBox(height: 12),
                SizedBox(
                  height: cardWidth + 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildRestaurantCard(context, 'Burger King', 'Hamburguesas', Colors.orange, cardWidth),
                      _buildRestaurantCard(context, "Carl's Jr", 'Hamburguesas', Colors.yellow.shade700, cardWidth),
                      _buildRestaurantCard(context, 'Sohoc', 'Sushi', Colors.red.shade400, cardWidth),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 6. Recomendados
                _buildSectionTitle('Recomendados'),
                const SizedBox(height: 12),
                SizedBox(
                  height: cardWidth + 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildRestaurantCard(context, 'Caffenio', 'Café', Colors.brown, cardWidth),
                      _buildRestaurantCard(context, "Burger King", 'Hamburguesas', Colors.orange, cardWidth),
                      _buildRestaurantCard(context, 'Sohoc', 'Sushi', Colors.red.shade400, cardWidth),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 7. Novedades
                _buildSectionTitle('Novedades'),
                const SizedBox(height: 12),
                SizedBox(
                  height: cardWidth + 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildRestaurantCard(context, 'Caffenio', 'Café', Colors.brown, cardWidth),
                      _buildRestaurantCard(context, 'La cocina de doña Li...', 'Mexicana', Colors.teal.shade200, cardWidth),
                      _buildRestaurantCard(context, 'Sohoc', 'Sushi', Colors.red.shade400, cardWidth),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      
      // 8. Nuestra barra de navegación reciclable
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  // --- FUNCIONES AYUDANTES --- //

  // Títulos con la flechita
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
      ],
    );
  }

  // Círculos de categorías
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
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Tarjetas de Restaurantes Grandes (Con navegación al detalle)
  Widget _buildRestaurantCard(BuildContext context, String name, String category, Color imageColor, double width) {
    return GestureDetector(
      onTap: () {
        // Al tocar la tarjeta, nos vamos a la pantalla gigante del restaurante
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RestaurantDetailScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: width,
                height: width, 
                decoration: BoxDecoration(
                  color: imageColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================
// WIDGET INTERACTIVO: Carrusel Automático para Destacados
// =======================================================
class AutoCarouselDestacados extends StatefulWidget {
  const AutoCarouselDestacados({super.key});

  @override
  State<AutoCarouselDestacados> createState() => _AutoCarouselDestacadosState();
}

class _AutoCarouselDestacadosState extends State<AutoCarouselDestacados> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _destacados = [
    {'name': 'Doña Licha', 'bgColor': Colors.teal.shade100, 'textColor': Colors.teal},
    {'name': 'Burger King', 'bgColor': Colors.orange.shade100, 'textColor': Colors.orange},
    {'name': 'Sushi Sohoc', 'bgColor': Colors.red.shade100, 'textColor': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _destacados.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
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
      itemCount: _destacados.length,
      itemBuilder: (context, index) {
        final item = _destacados[index];
        return Container(
          decoration: BoxDecoration(
            color: item['bgColor'],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '${item['name']}\n(Imagen aquí)',
            textAlign: TextAlign.center,
            style: TextStyle(color: item['textColor'], fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}