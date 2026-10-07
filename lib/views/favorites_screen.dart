import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../models/favorite_model.dart';
import '../models/user_model.dart';
import '../services/favorites_service.dart';
import '../services/user_service.dart';
import 'restaurant_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? _profile;
  List<FavoriteModel> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileFuture = UserService.getMyProfile();
      final favoritesFuture = FavoritesService.getMyFavorites();

      final results = await Future.wait([profileFuture, favoritesFuture]);

      setState(() {
        _profile = results[0] as UserModel;
        _favorites = results[1] as List<FavoriteModel>;
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sección Superior (Fondo gris con Stack para asegurar la X)
                      Container(
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        padding: const EdgeInsets.only(top: 16, bottom: 20),
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Botón X clavado a la izquierda
                            Positioned(
                              left: 24,
                              top: 0,
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
                                    Navigator.pop(context); 
                                  },
                                ),
                              ),
                            ),
                            
                            // Foto y Nombre centrados
                            Column(
                              children: [
                                Container(
                                  width: 100, 
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                    color: Colors.yellow.shade200, 
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _profile?.profileName?.isNotEmpty == true ? _profile!.profileName![0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 50, color: Colors.black54, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _profile?.profileName ?? 'Usuario',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Sección Inferior (Lista de Favoritos)
                      Expanded(
                        child: _favorites.isEmpty
                            ? const Center(child: Text('Aún no tienes restaurantes favoritos.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(24.0),
                                itemCount: _favorites.length + 1, // +1 para el título
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 24.0),
                                      child: Text(
                                        'Mis favoritos',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  
                                  final favorite = _favorites[index - 1];
                                  final colors = [Colors.teal, Colors.brown, Colors.orange, Colors.red, Colors.blue, Colors.purple];
                                  final color = colors[favorite.idRestaurant % colors.length];
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 24.0),
                                    child: _buildFavoriteItem(context, favorite, color.withOpacity(0.2), color),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  // --- FUNCIÓN AYUDANTE --- //
  Widget _buildFavoriteItem(BuildContext context, FavoriteModel favorite, Color bgColor, Color textColor) {
    final name = favorite.restaurantName ?? 'Restaurante';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurantId: favorite.idRestaurant)),
        ).then((_) {
          // Refrescar al volver por si quitó el favorito
          _loadData();
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 130, 
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12), 
            ),
            alignment: Alignment.center,
            child: Text(
              '$name\n(Banner aquí)',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}