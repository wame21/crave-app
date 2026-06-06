import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = true;
  String _userName = 'Cargando...';
  List<dynamic> _misResenas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final userId = await ApiService.obtenerUsuarioId();
    if (userId != null) {
      final perfil = await ApiService.obtenerPerfil(userId);
      final resenas = await ApiService.obtenerResenasPropias(userId);

      if (mounted) {
        setState(() {
          _userName = perfil?['profile_name'] ?? 'Usuario';
          _misResenas = resenas;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sección Superior
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 20,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 24,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                            color: Colors.yellow.shade200,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sección Inferior (Lista de Reseñas)
                  Expanded(
                    child: _misResenas.isEmpty
                        ? const Center(
                            child: Text(
                              'Aún no has escrito reseñas w.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Mis reseñas',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                ..._misResenas.map((review) {
                                  final restData = review['restaurants'] ?? {};
                                  final restName =
                                      restData['name'] ?? 'Restaurante';

                                  // Ajusta estos nombres según las columnas que haya creado tu compa en la BD
                                  final ratingStr =
                                      review['overall_rating']?.toString() ??
                                      '5.0';
                                  final reviewText =
                                      review['comment'] ??
                                      review['review_text'] ??
                                      'Sin comentario';
                                  final rawDate = review['created_at'] ?? '';
                                  // Cortamos la fecha para que no salga la hora tan fea
                                  final shortDate = rawDate.length > 10
                                      ? rawDate.substring(0, 10)
                                      : rawDate;

                                  return _buildReviewItem(
                                    restaurantName: restName,
                                    userName: _userName,
                                    rating: ratingStr,
                                    reviewText: reviewText,
                                    date: shortDate,
                                  );
                                }),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  // --- FUNCIÓN AYUDANTE --- //
  Widget _buildReviewItem({
    required String restaurantName,
    required String userName,
    required String rating,
    required String reviewText,
    required String date,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                restaurantName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black54,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
                color: Colors.yellow.shade200,
              ),
              child: const Icon(Icons.person, size: 28, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.yellow.shade700,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reviewText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}
