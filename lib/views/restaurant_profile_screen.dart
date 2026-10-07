import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'login_screen.dart';
import 'restaurant_detail_screen.dart';
import 'edit_restaurant_screen.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import '../services/auth_service.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  RestaurantModel? _restaurant;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final restaurant = await RestaurantService.getMyRestaurant();
      setState(() {
        _restaurant = restaurant;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _errorMessage != null && _restaurant == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _handleLogout,
                          child: const Text('Cerrar sesión'),
                        )
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // 1. Sección Superior (Banner + Logo + Nombre)
                      Container(
                        color: Colors.grey.shade200, 
                        child: Column(
                          children: [
                            // Stack para encimar el logo sobre el banner
                            Stack(
                              clipBehavior: Clip.none, 
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Banner del restaurante
                                Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade300, 
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.white54),
                                ),
                                // Logo circular encimado
                                Positioned(
                                  bottom: -50,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.teal.shade100,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ), 
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _restaurant!.name.isNotEmpty ? _restaurant!.name[0].toUpperCase() : 'R',
                                      style: const TextStyle(fontSize: 40, color: Colors.teal, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 60), 
                            // Nombre del restaurante
                            Text(
                              _restaurant!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20), 
                          ],
                        ),
                      ),

                      // 2. Sección Inferior (Botones sobre fondo blanco)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 30),

                              // Botón: Mi Restaurante
                              _buildProfileButton('Mi Restaurante', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RestaurantDetailScreen(restaurantId: _restaurant!.idRestaurant),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),

                              // Botón: Editar Restaurante
                              _buildProfileButton('Editar Restaurante', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditRestaurantScreen(),
                                  ),
                                ).then((_) => _loadRestaurant());
                              }),
                              const SizedBox(height: 40),

                              // Botón: Cerrar Sesión (Destructivo)
                              _buildProfileButton('Cerrar sesión', _handleLogout),
                              const SizedBox(height: 20),
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
  Widget _buildProfileButton(String text, VoidCallback onPressed) {
    bool isLogout = text == 'Cerrar sesión';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: isLogout ? Colors.red.shade400 : Colors.black87,
            width: isLogout ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isLogout ? Colors.red.shade400 : Colors.black,
            fontSize: 16,
            fontWeight: isLogout ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
