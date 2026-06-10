import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart';
import 'edit_restaurant_screen.dart'; // Para que el botón de editar te mande a la pantalla correcta

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  bool _isLoading = true;
  String _restaurantName = 'Cargando...';
  String _restaurantLocation = 'Sin dirección';
  String _restaurantCategory = 'Categoría';

  @override
  void initState() {
    super.initState();
    _cargarMiPerfilDeRestaurante();
  }

  // La magia que va a la base de datos y borra a Doña Licha
  Future<void> _cargarMiPerfilDeRestaurante() async {
    try {
      final userId = await ApiService.obtenerUsuarioId();
      if (userId != null) {
        final miRestaurante = await ApiService.obtenerMiRestaurante(userId);

        if (mounted) {
          setState(() {
            if (miRestaurante != null) {
              // Si tienes restaurante, ponemos tus datos reales w
              _restaurantName = miRestaurante['name'] ?? 'Mi Restaurante';
              _restaurantLocation =
                  miRestaurante['location'] ?? 'Configura tu dirección';
              _restaurantCategory = miRestaurante['food_type'] ?? 'Comida';
            } else {
              // Si no lo has creado, te avisa
              _restaurantName = 'Aún no configuras tu restaurante';
              _restaurantLocation = 'Dale en el botón de editar w';
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
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
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mi Perfil',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            onPressed: () async {
                              await ApiService.cerrarSesion();
                              // Ajusta esto según cómo se llame tu pantalla de inicio de sesión
                              Navigator.of(
                                context,
                              ).pushNamedAndRemoveUntil('/', (route) => false);
                            },
                          ),
                        ],
                      ),
                    ),

                    // --- BANNER Y FOTO ---
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 160,
                          color: Colors.pink.shade200,
                        ),
                        Positioned(
                          bottom: -50,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // --- INFO DEL RESTAURANTE REAL ---
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              _restaurantName, // <-- AQUÍ SALE TU NOMBRE REAL W
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_restaurantCategory • $_restaurantLocation',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // BOTÓN DE EDITAR
                            SizedBox(
                              width: 200,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditRestaurantScreen(),
                                    ),
                                  ).then((_) {
                                    // Cuando regreses de guardar, recarga la pantalla para mostrar los cambios
                                    setState(() => _isLoading = true);
                                    _cargarMiPerfilDeRestaurante();
                                  });
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  'Editar Perfil',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow.shade200,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 4,
      ), // Índice del Perfil
    );
  }
}
