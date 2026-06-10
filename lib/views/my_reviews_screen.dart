import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/review_service.dart';
import '../services/user_service.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? _profile;
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
      final profileFuture = UserService.getMyProfile();
      final reviewsFuture = ReviewService.getMyReviews();

      final results = await Future.wait([profileFuture, reviewsFuture]);

      setState(() {
        _profile = results[0] as UserModel;
        _reviews = results[1] as List<ReviewModel>;
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
                      // Sección Superior (Fondo gris clarito con el botón X)
                      Container(
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        padding: const EdgeInsets.only(top: 16, bottom: 20, left: 24, right: 24),
                        child: Column(
                          children: [
                            // Botón X alineado a la izquierda
                            Align(
                              alignment: Alignment.topLeft,
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
                                    Navigator.pop(context); // Regresa al perfil
                                  },
                                ),
                              ),
                            ),

                            // Foto de perfil
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
                            
                            // Nombre del usuario
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
                      ),

                      // Sección Inferior (Lista de Reseñas)
                      Expanded(
                        child: _reviews.isEmpty
                            ? const Center(child: Text('Aún no has publicado reseñas.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(24.0),
                                itemCount: _reviews.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 24.0),
                                      child: Text(
                                        'Mis reseñas',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }

                                  final review = _reviews[index - 1];
                                  final rating = ((review.ratingFood ?? 5) + (review.ratingService ?? 5) + (review.ratingAtmosphere ?? 5)) / 3.0;

                                  return _buildReviewItem(
                                    restaurantName: review.restaurantName ?? 'Restaurante',
                                    userName: _profile?.profileName ?? 'Usuario',
                                    rating: rating.toStringAsFixed(1),
                                    reviewText: review.comment ?? '',
                                    date: review.createdAt != null ? DateTime.parse(review.createdAt!).toLocal().toString().split(' ')[0] : '',
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
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
              alignment: Alignment.center,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 24, color: Colors.black54, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow.shade700, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    reviewText,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
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