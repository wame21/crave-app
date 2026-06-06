import '../services/api_services.dart';
import '../components/auto_carousel.dart';
import '../components/restaurants_cards.dart';
import '../components/custom_bottom_nav.dart';
import 'search_screen.dart';
import 'package:flutter/material.dart';

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
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Destacados\ndel día',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 90,
                        child:
                            AutoCarouselDestacados(), // <-- Aquí está tu widget limpio
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
                              id: '2',
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
