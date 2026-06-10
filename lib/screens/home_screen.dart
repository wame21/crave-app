import '../services/api_services.dart';
import '../components/restaurants_cards.dart';
import '../components/custom_bottom_nav.dart';
import 'search_screen.dart';
import 'restaurant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Necesario para que el carrusel de vueltas
import 'dart:math'; // Para sacar restaurantes aleatorios

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _restaurantes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Ahora le pedimos los datos al ApiService en lugar de tener todo el código HTTP aquí
  Future<void> _cargarDatos() async {
    final datos = await ApiService.getRestaurants();
    setState(() {
      _restaurantes = datos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 500) {
      screenWidth = 500;
    }
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
                // Barra de búsqueda
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) =>
                            const SearchScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Buscar',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                      ),
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

                // Banner Destacados (Llamamos a la pieza)
                Row(
                  // <-- AQUÍ LE QUITÉ EL CONST PARA QUE YA NO MARQUE ERROR W
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Destacados\ndel día',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 90,
                        child: AutoCarouselDestacados(
                          restaurantes: _restaurantes,
                        ), // <-- Pasamos los restaurantes
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Novedades (Llamamos a las tarjetas)
                const Text(
                  'Novedades',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: cardWidth + 50,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.black),
                        )
                      : _restaurantes.isEmpty
                      ? const Center(child: Text('No hay restaurantes aún'))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _restaurantes.length,
                          itemBuilder: (context, index) {
                            final rest = _restaurantes[index];
                            return RestaurantCard(
                              id: rest['id_restaurant']?.toString() ?? '0',
                              name: rest['name'] ?? 'Sin nombre',
                              category: rest['food_type'] ?? 'Variado',
                              imageColor: Colors.teal.shade200,
                              width: cardWidth,
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }
}

// =======================================================
// WIDGET: Carrusel de Destacados para el Home
// =======================================================
class AutoCarouselDestacados extends StatefulWidget {
  final List<dynamic> restaurantes;

  const AutoCarouselDestacados({super.key, required this.restaurantes});

  @override
  State<AutoCarouselDestacados> createState() => _AutoCarouselDestacadosState();
}

class _AutoCarouselDestacadosState extends State<AutoCarouselDestacados> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<Map<String, dynamic>> items = [];

  // Colores para alternar
  final List<Color> _colores = [
    Colors.orange.shade200,
    Colors.teal.shade200,
    Colors.pink.shade200,
  ];

  @override
  void initState() {
    super.initState();
    _prepararItems();

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (items.isEmpty) return;

      if (_currentPage < items.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(AutoCarouselDestacados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restaurantes != oldWidget.restaurantes) {
      setState(() {
        _prepararItems();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _prepararItems() {
    if (widget.restaurantes.isEmpty) {
      items = [
        {
          'text': 'Explora la app',
          'color': Colors.grey.shade300,
          'id': null,
          'name': null,
        },
      ];
      return;
    }

    final random = Random();
    List<dynamic> shuffled = List.from(widget.restaurantes)..shuffle(random);
    int take = shuffled.length > 3 ? 3 : shuffled.length;

    for (int i = 0; i < take; i++) {
      final rest = shuffled[i];
      final name = rest['name'] ?? 'Restaurante';
      final id = rest['id_restaurant']?.toString();

      String prompt = '';
      if (i == 0) {
        prompt = '¡Prueba $name!';
      } else if (i == 1)
        prompt = 'Te recomendamos $name';
      else
        prompt = 'Descubre $name';

      items.add({
        'text': prompt,
        'color': _colores[i % _colores.length],
        'id': id,
        'name': name,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && widget.restaurantes.isNotEmpty) {
      _prepararItems();
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (int page) => setState(() => _currentPage = page),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            if (item['id'] != null && item['name'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantDetailScreen(
                    restaurantId: item['id'],
                    restaurantName: item['name'],
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: item['color'],
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              item['text'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }
}
