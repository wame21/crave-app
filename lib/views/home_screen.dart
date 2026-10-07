import 'package:flutter/material.dart';
import 'dart:async'; 
import '../components/custom_bottom_nav.dart';
import 'search_screen.dart';
import 'restaurant_detail_screen.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant_model.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  List<RestaurantModel> _destacados = [];
  List<RestaurantModel> _mejorValorados = [];
  List<RestaurantModel> _novedades = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final data = await RestaurantService.getHomeData();
      setState(() {
        _destacados = data['destacados'] ?? [];
        _mejorValorados = data['mejor_valorados'] ?? [];
        _novedades = data['novedades'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
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
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadHomeData();
                          },
                          child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
                        )
                      ],
                    ),
                  )
                : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Barra de búsqueda 
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
                    enabled: false, 
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

                // 2. Botón de Favoritos 
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Modifica esto para navegar a FavoritesScreen:
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FavoritesScreen()),
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

                // 3. Banner Destacados del día 
                if (_destacados.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Destacados\ndel día',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 90,
                          child: AutoCarouselDestacados(destacados: _destacados),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],

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
                if (_mejorValorados.isNotEmpty) ...[
                  _buildSectionTitle('Mejor valorados'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: cardWidth + 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _mejorValorados.length,
                      itemBuilder: (context, index) {
                        return _buildRestaurantCard(context, _mejorValorados[index], Colors.orange, cardWidth);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // 6. Novedades
                if (_novedades.isNotEmpty) ...[
                  _buildSectionTitle('Novedades'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: cardWidth + 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _novedades.length,
                      itemBuilder: (context, index) {
                        return _buildRestaurantCard(context, _novedades[index], Colors.teal.shade200, cardWidth);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
      
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  // --- FUNCIONES AYUDANTES --- //

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

  Widget _buildCategoryItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Al hacer tap, navega a SearchScreen pasando el label de la categoría:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(initialCategory: label),
          ),
        );
      },
      child: Padding(
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
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, RestaurantModel restaurant, Color imageColor, double width) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurantId: restaurant.idRestaurant)),
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
                child: const Center(child: Icon(Icons.restaurant, color: Colors.white54, size: 40)),
              ),
              const SizedBox(height: 8),
              Text(
                restaurant.foodType ?? 'Categoría',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(
                    ' ${restaurant.overallRating?.toStringAsFixed(1) ?? "0.0"}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
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
  final List<RestaurantModel> destacados;

  const AutoCarouselDestacados({super.key, required this.destacados});

  @override
  State<AutoCarouselDestacados> createState() => _AutoCarouselDestacadosState();
}

class _AutoCarouselDestacadosState extends State<AutoCarouselDestacados> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Color> _bgColors = [Colors.teal.shade100, Colors.orange.shade100, Colors.red.shade100, Colors.blue.shade100];
  final List<Color> _textColors = [Colors.teal, Colors.orange, Colors.red, Colors.blue];

  @override
  void initState() {
    super.initState();
    if (widget.destacados.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (_currentPage < widget.destacados.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destacados.isEmpty) return const SizedBox.shrink();
    
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (int page) {
        setState(() {
          _currentPage = page;
        });
      },
      itemCount: widget.destacados.length,
      itemBuilder: (context, index) {
        final restaurant = widget.destacados[index];
        final colorIndex = index % _bgColors.length;
        return Container(
          decoration: BoxDecoration(
            color: _bgColors[colorIndex],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '${restaurant.name}\n(Destacado)',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textColors[colorIndex], fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}