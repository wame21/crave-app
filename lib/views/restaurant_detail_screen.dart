import 'package:flutter/material.dart';
import 'dart:async';
import '../components/custom_bottom_nav.dart';
import 'all_reviews_screen.dart';
import 'create_review_screen.dart';
import '../models/restaurant_model.dart';
import '../models/review_model.dart';
import '../models/favorite_model.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';
import '../services/favorites_service.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final int restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  RestaurantModel? _restaurant;
  List<ReviewModel> _reviews = [];
  bool _isFavorite = false;

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
      final restaurantFuture = RestaurantService.getRestaurant(widget.restaurantId);
      final reviewsFuture = ReviewService.getRestaurantReviews(widget.restaurantId);
      final favoritesFuture = FavoritesService.getMyFavorites();

      final results = await Future.wait([restaurantFuture, reviewsFuture, favoritesFuture]);

      _restaurant = results[0] as RestaurantModel;
      _reviews = results[1] as List<ReviewModel>;
      final favorites = results[2] as List<FavoriteModel>;

      _isFavorite = favorites.any((f) => f.idRestaurant == widget.restaurantId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await FavoritesService.removeFavorite(widget.restaurantId);
        setState(() => _isFavorite = false);
      } else {
        await FavoritesService.addFavorite(widget.restaurantId);
        setState(() => _isFavorite = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_errorMessage != null || _restaurant == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
        body: Center(child: Text(_errorMessage ?? 'Restaurante no encontrado')),
      );
    }

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
                      color: Colors.teal.shade200, 
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant, size: 80, color: Colors.white54),
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
                        color: _isFavorite ? Colors.red.shade100 : Colors.yellow.shade200, 
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: IconButton(
                        icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.black),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: _toggleFavorite,
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
                          child: Text(
                            _restaurant!.name.isNotEmpty ? _restaurant!.name[0].toUpperCase() : 'R',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _restaurant!.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _restaurant!.foodType ?? 'Restaurante',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.yellow.shade700, size: 24),
                            const SizedBox(width: 4),
                            Text(
                              _restaurant!.overallRating?.toStringAsFixed(1) ?? "0.0",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                    // 7. Reseñas
                    const Text('Reseñas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    if (_reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text('Aún no hay reseñas.', style: TextStyle(color: Colors.black54)),
                      )
                    else
                      ..._reviews.take(3).map((review) => _buildReviewItem(
                        userName: review.clientName ?? 'Usuario Anónimo',
                        rating: ((review.ratingFood ?? 5) + (review.ratingService ?? 5) + (review.ratingAtmosphere ?? 5)) / 3.0,
                        reviewText: review.comment ?? '',
                        date: review.createdAt != null ? DateTime.parse(review.createdAt!).toLocal().toString().split(' ')[0] : 'Reciente',
                        avatarColor: Colors.blueGrey,
                      )),

                    // 8. Botón Mas reseñas (Conecta a AllReviewsScreen)
                    if (_reviews.length > 3)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AllReviewsScreen(restaurantId: widget.restaurantId)),
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
                            MaterialPageRoute(builder: (context) => CreateReviewScreen(restaurantId: widget.restaurantId)),
                          ).then((value) {
                            if (value == true) {
                              _loadData(); // Recargar si se creó una reseña
                            }
                          });
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
              Text(_restaurant?.openingHours ?? 'Horario no disponible.', textAlign: TextAlign.center,),
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

  Widget _buildReviewItem({
    required String userName,
    required double rating,
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
                          Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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