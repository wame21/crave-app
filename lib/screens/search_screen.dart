import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart';
import 'restaurant_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Variables de estado
  List<dynamic> _allRestaurants = [];
  List<dynamic> _filteredRestaurants = [];
  List<Map<String, dynamic>> _recentSearches =
      []; // <-- Memoria real de los recientes

  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarRestaurantes();
    _cargarRecientes(); // Cargamos tu historial real al entrar
  }

  // 1. Descarga todos los restaurantes
  Future<void> _cargarRestaurantes() async {
    final restaurantes = await ApiService.getRestaurants();
    if (mounted) {
      setState(() {
        _allRestaurants = restaurantes;
        _filteredRestaurants = restaurantes;
        _isLoading = false;
      });
    }
  }

  // 2. Carga los restaurantes a los que le has picado antes (desde la memoria)
  Future<void> _cargarRecientes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? recentsJson = prefs.getStringList('recent_searches');

    if (recentsJson != null && mounted) {
      setState(() {
        _recentSearches = recentsJson
            .map((item) => json.decode(item) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  // 3. Guarda un restaurante en el historial cuando le picas
  Future<void> _guardarEnRecientes(dynamic restaurante) async {
    final prefs = await SharedPreferences.getInstance();

    // Armamos un mini-perfil con lo básico del restaurante
    final nuevoReciente = {
      'id_restaurant': restaurante['id_restaurant'].toString(),
      'name': restaurante['name'] ?? 'Sin nombre',
      'overall_rating': restaurante['overall_rating']?.toString() ?? '5.0',
    };

    setState(() {
      // Si ya estaba en la lista, lo borramos para ponerlo hasta arriba (no duplicados)
      _recentSearches.removeWhere(
        (item) => item['id_restaurant'] == nuevoReciente['id_restaurant'],
      );
      _recentSearches.insert(0, nuevoReciente);

      // Solo guardamos los 5 más recientes para no atascar la pantalla
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });

    // Lo guardamos en el celular convirtiéndolo a texto
    final recentsStringList = _recentSearches
        .map((item) => json.encode(item))
        .toList();
    await prefs.setStringList('recent_searches', recentsStringList);
  }

  // 4. El filtro en tiempo real
  void _filtrarBusqueda(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRestaurants = _allRestaurants;
      } else {
        _filteredRestaurants = _allRestaurants.where((restaurante) {
          final nombre = restaurante['name'].toString().toLowerCase();
          final tipo = restaurante['food_type']?.toString().toLowerCase() ?? '';
          return nombre.contains(query.toLowerCase()) || tipo.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // --- BARRA DE BÚSQUEDA ---
              TextField(
                controller: _searchController,
                onChanged: _filtrarBusqueda,
                autofocus: true,
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

              // --- ZONA DINÁMICA ---
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                    : _searchQuery.isEmpty
                    ? _buildDefaultView()
                    : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  // ==========================================
  // VISTA 1: Cuando la barra está vacía (Categorías + Recientes REALES)
  // ==========================================
  Widget _buildDefaultView() {
    return ListView(
      children: [
        // Categorías (Estas se quedan fijas por diseño w)
        Row(
          children: const [
            Text(
              'Categorías',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
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
              _buildCategoryItem(Icons.local_dining, 'Tacos'),
              _buildCategoryItem(Icons.fastfood, 'Alitas'),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // --- ÚLTIMOS BUSCADOS (DINÁMICOS) ---
        const Text(
          'Últimos buscados:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (_recentSearches.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Aún no hay búsquedas recientes w.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          )
        else
          ..._recentSearches.map((restaurante) {
            return InkWell(
              onTap: () {
                // Al picarle a un reciente, te manda directo a su perfil
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailScreen(
                      restaurantId: restaurante['id_restaurant'].toString(),
                      restaurantName: restaurante['name'],
                    ),
                  ),
                );
              },
              child: _buildStaticRecentItem(
                restaurante['name'],
                restaurante['overall_rating'],
                Colors.teal.shade100,
                Colors.teal,
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // VISTA 2: Resultados cuando estás escribiendo
  // ==========================================
  Widget _buildSearchResults() {
    if (_filteredRestaurants.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron restaurantes 😢',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurante = _filteredRestaurants[index];
        final name = restaurante['name'] ?? 'Sin nombre';
        final rating = restaurante['overall_rating']?.toString() ?? '5.0';

        return InkWell(
          onTap: () async {
            // ¡MAGIA! Aquí lo guardamos en el historial antes de navegar
            await _guardarEnRecientes(restaurante);

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantDetailScreen(
                    restaurantId: restaurante['id_restaurant'].toString(),
                    restaurantName: name,
                  ),
                ),
              );
            }
          },
          child: _buildStaticRecentItem(
            name,
            rating,
            Colors.pink.shade100,
            Colors.pink,
          ),
        );
      },
    );
  }

  // ==========================================
  // FUNCIONES AYUDANTES (Diseño)
  // ==========================================
  Widget _buildCategoryItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: InkWell(
        onTap: () {
          // Actualizamos la barra de búsqueda visualmente y filtramos
          _searchController.text = label;
          _filtrarBusqueda(label);
        },
        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildStaticRecentItem(
    String name,
    String rating,
    Color bgColor,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: iconColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
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
