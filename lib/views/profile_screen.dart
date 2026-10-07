import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'my_reviews_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await UserService.getMyProfile();
      setState(() {
        _profile = profile;
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
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
                        TextButton(
                          onPressed: _handleLogout,
                          child: const Text('Cerrar sesión y salir'),
                        )
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sección Superior (Fondo gris clarito)
                      Container(
                        width: double.infinity, 
                        color: Colors.grey.shade200, 
                        padding: const EdgeInsets.only(top: 60, bottom: 30),
                        child: Column(
                          children: [
                            // Foto de perfil
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                                color: Colors.yellow.shade200, 
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _profile?.profileName?.isNotEmpty == true ? _profile!.profileName![0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 60, color: Colors.black54, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Nombre del usuario
                            Text(
                              _profile?.profileName ?? 'Usuario',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Sección Inferior (Botones sobre fondo blanco)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              
                              // Botones de opciones
                              _buildProfileButton('Editar Perfil', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                ).then((_) => _loadProfile()); // Recargar si editó
                              }),
                              const SizedBox(height: 16),
                              
                              _buildProfileButton('Mis Favoritos', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                                );
                              }),
                              const SizedBox(height: 16),
                              
                              _buildProfileButton('Reseñas Publicadas', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MyReviewsScreen()),
                                );
                              }),
                              const SizedBox(height: 40), 

                              // Botón de Cerrar Sesión
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
    return SizedBox(
      width: double.infinity, 
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white, 
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: text == 'Cerrar sesión' ? Colors.red.shade400 : Colors.black87,
            width: text == 'Cerrar sesión' ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: text == 'Cerrar sesión' ? Colors.red.shade400 : Colors.black,
            fontSize: 16,
            fontWeight: text == 'Cerrar sesión' ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}