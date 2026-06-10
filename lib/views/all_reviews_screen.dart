import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';

class AllReviewsScreen extends StatefulWidget {
  final int restaurantId;
  const AllReviewsScreen({super.key, required this.restaurantId});

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  RestaurantModel? _restaurant;
  List<ReviewModel> _reviews = [];

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

      final results = await Future.wait([restaurantFuture, reviewsFuture]);

      _restaurant = results[0] as RestaurantModel;
      _reviews = results[1] as List<ReviewModel>;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _errorMessage != null || _restaurant == null
                ? Center(child: Text(_errorMessage ?? 'Error al cargar reseñas'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Cabecera Central
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'Todas las reseñas de:',
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Logo
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
                                    child: Text(
                                      _restaurant!.name,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Estrella y Calificación
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.yellow.shade700, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          _restaurant!.overallRating?.toStringAsFixed(1) ?? "0.0",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 2. Título de la sección
                        const Text(
                          'Reseñas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 20),

                        // 3. Lista de Reseñas Detalladas
                        if (_reviews.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('Este restaurante aún no tiene reseñas.', style: TextStyle(color: Colors.black54)),
                            ),
                          )
                        else
                          ..._reviews.map((review) => _buildDetailedReviewItem(
                                userName: review.clientName ?? 'Usuario Anónimo',
                                date: review.createdAt != null ? DateTime.parse(review.createdAt!).toLocal().toString().split(' ')[0] : '',
                                reviewText: review.comment ?? '',
                                avatarColor: Colors.blueGrey,
                                hasImage: (review.photoGallery?.isNotEmpty ?? false),
                                servicio: (review.ratingService ?? 5).toStringAsFixed(1),
                                comida: (review.ratingFood ?? 5).toStringAsFixed(1),
                                ambiente: (review.ratingAtmosphere ?? 5).toStringAsFixed(1),
                              )),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  // --- FUNCIONES AYUDANTES --- //

  Widget _buildDetailedReviewItem({
    required String userName,
    required String date,
    required String reviewText,
    required Color avatarColor,
    required bool hasImage,
    required String servicio,
    required String comida,
    required String ambiente,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Avatar, Nombre y Fecha
        Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
                border: Border.all(color: Colors.black54, width: 1),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              userName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Spacer(), // Empuja la fecha hasta la derecha
            Text(
              date,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fila 2: Texto de la reseña
        Text(
          reviewText,
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // Fila 3: Imagen (Solo se dibuja si hasImage es true)
        if (hasImage) ...[
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade100, // Color de placeholder
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('Foto subida por el usuario', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          const SizedBox(height: 16),
        ],

        // Fila 4: Calificaciones Detalladas (Servicio, Comida, Ambiente)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniRating('Servicio', servicio),
            const SizedBox(width: 16),
            _buildMiniRating('Comida', comida),
            const SizedBox(width: 16),
            _buildMiniRating('Ambiente', ambiente),
          ],
        ),
        const SizedBox(height: 16),

        // Línea divisoria
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  // Pequeño widget para "Servicio ⭐5.0"
  Widget _buildMiniRating(String label, String rating) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(width: 4),
        Icon(Icons.star, color: Colors.yellow.shade700, size: 16),
        Text(
          rating,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }
}