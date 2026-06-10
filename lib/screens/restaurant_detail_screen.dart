import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart';
import 'all_reviews_screen.dart';
import 'create_review_screen.dart';
import 'home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  String? _userId;
  String _userRole = 'Client'; // Por defecto es cliente
  bool _isFavorite = false;
  bool _isLoading = true;
  List<dynamic> _resenas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosRestaurante();
  }

  Future<void> _cargarDatosRestaurante() async {
    // 1. LEEMOS EL ROL REAL DE LA MEMORIA DEL CELULAR W
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'Client';

    final userId = await ApiService.obtenerUsuarioId();
    if (userId != null) {
      final isFav = await ApiService.checarSiEsFavorito(
        userId,
        widget.restaurantId,
      );
      final resenas = await ApiService.obtenerResenasRestaurante(
        widget.restaurantId,
      );

      if (mounted) {
        setState(() {
          _userRole = role; // <-- GUARDAMOS EL ROL PARA USARLO ABAJO
          _userId = userId;
          _isFavorite = isFav;
          _resenas = resenas;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleFavorito() async {
    if (_userId == null) return;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    bool exito = false;
    if (_isFavorite) {
      // AQUÍ ESTÁ EL FIX: Le mandamos el _userId! y el widget.restaurantId
      exito = await ApiService.agregarFavorito(_userId!, widget.restaurantId);
    } else {
      // AQUÍ TAMBIÉN: Le mandamos los dos datos
      exito = await ApiService.quitarFavorito(_userId!, widget.restaurantId);
    }

    if (!exito && mounted) {
      setState(() {
        _isFavorite = !_isFavorite; // Lo regresamos a como estaba si falla
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error de conexión w, intenta de nuevo.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } else if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Restaurante marcado como favorito' : 'Restaurante quitado de favoritos'),
          backgroundColor: Colors.green.shade600,
        ),
      );
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
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.pink.shade200,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Imagen de platillo aquí',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade200,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : Colors.black,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: _toggleFavorito,
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
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.restaurantName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Abierto ahora: Cierra a las 07:00 PM.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.yellow.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.8',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final Uri telUrl = Uri.parse('tel:1234567890');
                                    if (await canLaunchUrl(telUrl)) {
                                      await launchUrl(telUrl);
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('No se puede abrir el teléfono w.',), backgroundColor: Colors.red,),
                                        );
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: const BorderSide(
                                      color: Colors.black87,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Llamar',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final query = Uri.encodeComponent(
                                      '${widget.restaurantName}, Guasave',
                                    );
                                    final url = Uri.parse(
                                      'https://www.google.com/maps/search/?api=1&query=$query',
                                    );

                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se pudo abrir Maps w.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: const BorderSide(
                                      color: Colors.black87,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cómo llegar',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Información',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoIconButton(
                                  Icons.camera_alt_outlined,
                                  () async {
                                    final Uri url = Uri.parse('https://instagram.com');
                                    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoIconButton(
                                  Icons.facebook,
                                  () async {
                                    final Uri url = Uri.parse('https://facebook.com');
                                    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoIconButton(
                                  Icons.watch_later_outlined,
                                  () => _showScheduleDialog(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Menú',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: GenericAutoCarousel(
                              items: [
                                {
                                  'text': 'Menú de Desayunos',
                                  'color': Colors.orange.shade200,
                                },
                                {
                                  'text': 'Menú de Comidas',
                                  'color': Colors.orange.shade300,
                                },
                                {
                                  'text': 'Bebidas y Postres',
                                  'color': Colors.orange.shade400,
                                },
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Reseñas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_resenas.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 20),
                              child: Text(
                                'Nadie ha opinado todavía. ¡Sé el primero w!',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          else
                            ..._resenas.map((review) {
                              final userData = review['users'] ?? {};
                              final nombre =
                                  userData['profile_name'] ?? 'Usuario anónimo';
                              final fechaRaw = review['created_at'] ?? '';
                              final fechaCorta = fechaRaw.length > 10
                                  ? fechaRaw.substring(0, 10)
                                  : fechaRaw;

                              return _buildReviewItem(
                                userName: nombre,
                                rating:
                                    review['overall_rating']?.toString() ??
                                    '5.0',
                                reviewText: review['comment'] ?? '',
                                date: fechaCorta,
                                avatarColor: Colors.blueGrey,
                              );
                            }),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AllReviewsScreen(),
                                ),
                              );
                            },
                            child: Row(
                              children: const [
                                Text(
                                  'Mas reseñas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. ¡EL SEGURO CONTRA DUEÑOS Y LA CONEXIÓN AL NOMBRE!
                          if (_userRole != 'Restaurant_Owner')
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateReviewScreen(
                                        restaurantId: widget.restaurantId,
                                        restaurantName: widget
                                            .restaurantName, // <-- LISTO PARA LA ACCIÓN
                                      ),
                                    ),
                                  ).then((_) {
                                    // RECARGAMOS LA PANTALLA AL VOLVER
                                    setState(() => _isLoading = true);
                                    _cargarDatosRestaurante();
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(color: Colors.black87),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '¿Qué te pareció este restaurante?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Horario de Atención',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildScheduleRow('Lunes', '08:00 AM - 07:00 PM'),
              _buildScheduleRow('Martes', '08:00 AM - 07:00 PM'),
              _buildScheduleRow('Miércoles', '08:00 AM - 07:00 PM'),
              _buildScheduleRow('Jueves', '08:00 AM - 07:00 PM'),
              _buildScheduleRow('Viernes', '08:00 AM - 09:00 PM'),
              _buildScheduleRow('Sábado', '09:00 AM - 10:00 PM'),
              _buildScheduleRow('Domingo', 'Cerrado', isClosed: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleRow(String day, String hours, {bool isClosed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isClosed ? FontWeight.bold : FontWeight.normal,
              color: isClosed ? Colors.red.shade400 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required String userName,
    required String rating,
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
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.yellow.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reviewText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
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

class GenericAutoCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const GenericAutoCarousel({super.key, required this.items});

  @override
  State<GenericAutoCarousel> createState() => _GenericAutoCarouselState();
}

class _GenericAutoCarouselState extends State<GenericAutoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < widget.items.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (int page) => setState(() => _currentPage = page),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Container(
          decoration: BoxDecoration(
            color: item['color'],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            item['text'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        );
      },
    );
  }
}
