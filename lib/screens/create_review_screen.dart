import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart';

class CreateReviewScreen extends StatefulWidget {
  final String restaurantId;
  final String
  restaurantName; // Añadimos esto para que la cabecera no diga Doña Licha w

  const CreateReviewScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  // Las estrellitas de tu diseño
  double _foodRating = 0.0;
  double _serviceRating = 0.0;
  double _ambienceRating = 0.0;

  // El controlador para el campo de texto (¿Por qué?)
  final TextEditingController _commentController = TextEditingController();

  // Para mostrar que la app está pensando y evitar doble click
  bool _isPublishing = false;

  // --- LÓGICA PARA PUBLICAR EN SUPABASE ---
  Future<void> _publicar() async {
    // Si no le han puesto ninguna estrella, le avisamos
    if (_foodRating == 0.0 && _serviceRating == 0.0 && _ambienceRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ponle al menos una estrellita loco.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    final userId = await ApiService.obtenerUsuarioId();
    if (userId == null) {
      setState(() => _isPublishing = false);
      return;
    }

    // Calculamos el promedio global juntando tus 3 categorías
    double overallRating = (_foodRating + _serviceRating + _ambienceRating) / 3;

    // Empaquetamos todo para mandarlo al servidor
    final datos = {
      'id_user': userId,
      'id_restaurant': widget.restaurantId,
      'rating_food': _foodRating.round(),
      'rating_service': _serviceRating.round(),
      'rating_atmosphere': _ambienceRating.round(),
      'comment': _commentController.text.trim(),
    };

    final exito = await ApiService.crearResena(datos);

    if (mounted) {
      setState(() => _isPublishing = false);

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reseña publicada al cien!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Te regresa a la pantalla del restaurante
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un pedo al publicar w.'),
            backgroundColor: Colors.red,
          ),
        );
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Realizar Reseña',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.teal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget
                              .restaurantName, // ¡Ya no es Doña Licha, es el nombre real!
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Evaluando...',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 2. Secciones de Calificación por Estrellas
              _buildStarRatingSection('Comida', _foodRating, (rating) {
                setState(() => _foodRating = rating);
              }),
              _buildStarRatingSection('Servicio', _serviceRating, (rating) {
                setState(() => _serviceRating = rating);
              }),
              _buildStarRatingSection('Ambiente', _ambienceRating, (rating) {
                setState(() => _ambienceRating = rating);
              }),

              const SizedBox(height: 30),

              // 3. Campo de Texto (¡CONECTADO AL CONTROLADOR!)
              const Center(
                child: Text(
                  '¿Por qué?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController, // <-- ESTO ATRAPA EL TEXTO
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

              // 4. Adjuntar Imágenes (Solo el botón de adorno por ahora)
              const Center(
                child: Text(
                  'Fotografías',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 5. Botón Publicar reseña (¡CONECTADO A LA BASE DE DATOS!)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isPublishing
                      ? null
                      : _publicar, // Si está cargando, lo bloquea
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isPublishing
                        ? Colors.grey.shade300
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Publicar reseña',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildStarRatingSection(
    String title,
    double currentRating,
    Function(double) onRatingChanged,
  ) {
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

  Widget _buildInteractiveStarRow(
    double rating,
    Function(double) onRatingChanged,
  ) {
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
            color: rating >= starValue - 0.5
                ? Colors.yellow.shade700
                : Colors.black87,
            size: 48,
          ),
        );
      }),
    );
  }
}
