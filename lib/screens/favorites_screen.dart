import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart'; // <-- Importamos tu API

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  String _userName = 'Cargando...';
  List<dynamic> _misFavoritos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final userId = await ApiService.obtenerUsuarioId();
    if (userId != null) {
      // Jalamos el perfil para el nombre y los favoritos al mismo tiempo
      final perfil = await ApiService.obtenerPerfil(userId);
      final favoritos = await ApiService.obtenerFavoritos(userId);
      if (mounted) {
        setState(() {
          _userName = perfil?['profile_name'] ?? 'Usuario';
          _misFavoritos = favoritos;
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
                  // Sección Superior (Fondo gris)
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    padding: const EdgeInsets.only(top: 16, bottom: 20),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          left: 24,
                          top: 0,
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

                        // Foto y Nombre Reales
                        Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
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
                              _userName, // <-- ¡Adiós Pedro Sánchez!
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sección Inferior (Lista de Favoritos Dinámica)
                  Expanded(
                    child: _misFavoritos.isEmpty
                        ? const Center(
                            child: Text(
                              'Aún no tienes restaurantes favoritos loco.',
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
                                  'Mis favoritos',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Mapeamos la lista real que viene de Supabase
                                ..._misFavoritos.map((fav) {
                                  // Supabase anida los datos del restaurante porque hicimos un join
                                  final restData = fav['restaurants'] ?? {};
                                  final restName =
                                      restData['name'] ??
                                      'Restaurante Desconocido';

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24.0,
                                    ),
                                    child: _buildFavoriteItem(
                                      restName,
                                      Colors
                                          .teal
                                          .shade100, // Puedes hacer esto dinámico después si quieres
                                      Colors.teal,
                                    ),
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
  Widget _buildFavoriteItem(String name, Color bgColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
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
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 130,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '$name\n(Banner aquí)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
