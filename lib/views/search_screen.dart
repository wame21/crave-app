import 'package:flutter/material.dart';
import 'dart:async';
import '../components/custom_bottom_nav.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant_model.dart';
import 'restaurant_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  bool _isLoading = false;
  String? _errorMessage;
  List<RestaurantModel> _searchResults = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await RestaurantService.listRestaurants(
        query: _searchController.text.trim(),
        category: _selectedCategory,
      );
      setState(() {
        _searchResults = results;
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
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar restaurantes...',
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
              const SizedBox(height: 20),

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
                    _buildCategoryItem(Icons.local_dining, 'Mexicana'),
                    _buildCategoryItem(Icons.ramen_dining, 'China'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Resultados:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Lista de resultados
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                        : _searchResults.isEmpty
                            ? const Center(child: Text('No se encontraron restaurantes', style: TextStyle(color: Colors.black54)))
                            : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final restaurant = _searchResults[index];
                                  return _buildResultItem(context, restaurant);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  // Círculos de categorías
  Widget _buildCategoryItem(IconData icon, String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _toggleCategory(label),
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.blue : Colors.black87, width: isSelected ? 3.0 : 2.5),
                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
              ),
              child: Icon(icon, size: 32, color: isSelected ? Colors.blue : Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filas de restaurantes
  Widget _buildResultItem(BuildContext context, RestaurantModel restaurant) {
    // Generar un color semi-aleatorio basado en el ID para variedad visual si no hay imagen
    final colors = [Colors.teal, Colors.brown, Colors.orange, Colors.red, Colors.blue, Colors.purple];
    final color = colors[restaurant.idRestaurant % colors.length];
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurantId: restaurant.idRestaurant)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                restaurant.name.isNotEmpty ? restaurant.name[0].toUpperCase() : 'R',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (restaurant.foodType != null)
                    Text(
                      restaurant.foodType!,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                ],
              ),
            ),
            Icon(Icons.star, color: Colors.yellow.shade700, size: 24),
            const SizedBox(width: 4),
            Text(
              restaurant.overallRating?.toStringAsFixed(1) ?? "0.0",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
