import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import '../services/review_service.dart';

class CreateReviewScreen extends StatefulWidget {
  final int restaurantId;
  const CreateReviewScreen({super.key, required this.restaurantId});

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  double _foodRating = 0.0;
  double _serviceRating = 0.0;
  double _ambienceRating = 0.0;
  
  final _commentController = TextEditingController();
  
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  RestaurantModel? _restaurant;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    try {
      final restaurant = await RestaurantService.getRestaurant(widget.restaurantId);
      setState(() {
        _restaurant = restaurant;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingData = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_foodRating == 0.0 || _serviceRating == 0.0 || _ambienceRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, califica todos los aspectos')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ReviewService.createReview(
        widget.restaurantId,
        _serviceRating.toInt(),
        _foodRating.toInt(),
        _ambienceRating.toInt(),
        _commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reseña publicada con éxito')),
      );
      Navigator.pop(context, true); // Retornamos true para indicar que se creó
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_errorMessage != null || _restaurant == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
        body: Center(child: Text(_errorMessage ?? 'Error al cargar')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Realizar Reseña',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, 
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context); 
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              // 1. Cabecera del Restaurante
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60, 
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100, 
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _restaurant!.name.isNotEmpty ? _restaurant!.name[0].toUpperCase() : 'R',
                      style: const TextStyle(color: Colors.teal, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _restaurant!.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _restaurant!.foodType ?? 'Restaurante',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
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
              const SizedBox(height: 40),

              // 2. Secciones de Calificación por Estrellas
              _buildStarRatingSection('Comida', _foodRating, (rating) {
                setState(() {
                  _foodRating = rating;
                });
              }),
              _buildStarRatingSection('Servicio', _serviceRating, (rating) {
                setState(() {
                  _serviceRating = rating;
                });
              }),
              _buildStarRatingSection('Ambiente', _ambienceRating, (rating) {
                setState(() {
                  _ambienceRating = rating;
                });
              }),

              const SizedBox(height: 30),

              // 3. Campo de Texto
              const Center(
                child: Text(
                  '¿Por qué?', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 5, 
                decoration: InputDecoration(
                  hintText: 'Comparte tu opinion',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.grey.shade100, 
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none, 
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 4. Adjuntar Imágenes (Solo UI por ahora)
              const Center(
                child: Text(
                  'Fotografías',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black87),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: const [
                      Icon(Icons.image_outlined, color: Colors.black, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Adjuntar Imagen',
                        style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40), 

              // 5. Botón Publicar reseña
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton( 
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white, 
                    side: const BorderSide(color: Colors.black87),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text(
                          'Publicar reseña',
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  // --- FUNCIONES AYUDANTES --- //

  Widget _buildStarRatingSection(String title, double currentRating, Function(double) onRatingChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          _buildInteractiveStarRow(currentRating, onRatingChanged),
        ],
      ),
    );
  }

  Widget _buildInteractiveStarRow(double rating, Function(double) onRatingChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: List.generate(5, (index) {
        double starValue = index + 1.0; 
        IconData iconData;

        if (rating >= starValue) {
          iconData = Icons.star;
        } else if (rating >= starValue - 0.5) {
          iconData = Icons.star_half;
        } else {
          iconData = Icons.star_border;
        }

        return GestureDetector(
          onTapDown: (TapDownDetails details) {
            if (details.localPosition.dx <= 24) {
              onRatingChanged(starValue - 0.5); 
            } else {
              onRatingChanged(starValue); 
            }
          },
          child: Icon(
            iconData,
            color: rating >= starValue - 0.5 ? Colors.yellow.shade700 : Colors.black87, 
            size: 48, 
          ),
        );
      }),
    );
  }
}