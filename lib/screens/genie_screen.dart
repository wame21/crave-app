import 'package:flutter/material.dart';
import 'dart:math';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart';

class GenieScreen extends StatefulWidget {
  const GenieScreen({super.key});

  @override
  State<GenieScreen> createState() => _GenieScreenState();
}

class _GenieScreenState extends State<GenieScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'genie',
      'text': '¡Hola! Soy el Genio de los antojos.\n¿Qué se te antoja hoy?'
    }
  ];

  final List<String> _options = [
    "Descubrir un nuevo sabor hoy",
    "Quiero probar otro tipo de comida",
    "Lo mejor para ti"
  ];

  List<dynamic> _misFavoritos = [];
  List<dynamic> _todosRestaurantes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final userId = await ApiService.obtenerUsuarioId();
    final todosRestaurantes = await ApiService.getRestaurants();

    if (userId != null) {
      final favoritos = await ApiService.obtenerFavoritos(userId);
      if (mounted) {
        setState(() {
          _misFavoritos = favoritos;
          _todosRestaurantes = todosRestaurantes;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _todosRestaurantes = todosRestaurantes;
          _isLoading = false;
        });
      }
    }
  }

  void _handleOptionSelected(String option) {
    setState(() {
      // Add user message
      _messages.add({'sender': 'user', 'text': option});
    });

    // Simulate typing delay
    Future.delayed(const Duration(seconds: 1), () {
      _generateResponse(option);
    });
  }

  void _generateResponse(String option) {
    String responseText = "Parece que hay un error mágico en mi lámpara.";

    if (_misFavoritos.isEmpty && _todosRestaurantes.isEmpty) {
      responseText =
          "Veo que aún no tienes restaurantes favoritos ni hay restaurantes en la app.\n¡Ve a buscar algunos lugares y agregalos a favoritos para que pueda darte mejores recomendaciones!";
    } else {
      final random = Random();
      
      // IDs de los restaurantes favoritos para poder excluirlos
      List<String> favIds = _misFavoritos
          .map((f) => f['restaurants']?['id_restaurant']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
          
      // Extraemos tipos de comida de los favoritos
      List<String> favCategories = _misFavoritos
          .map((f) => f['restaurants']?['food_type']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toList();
      
      if (option == "Descubrir un nuevo sabor hoy" || option == "Quiero probar otro tipo de comida") {
        // Buscar restaurantes que NO estén en los favoritos y cuya categoría NO sea favorita
        List<dynamic> nonFavRestaurants = _todosRestaurantes.where((r) {
          final id = r['id_restaurant']?.toString() ?? '';
          final category = r['food_type']?.toString() ?? '';
          return !favIds.contains(id) && !favCategories.contains(category);
        }).toList();
        
        // Si no hay con categorías nuevas, al menos uno que no sea favorito
        if (nonFavRestaurants.isEmpty) {
          nonFavRestaurants = _todosRestaurantes.where((r) {
            final id = r['id_restaurant']?.toString() ?? '';
            return !favIds.contains(id);
          }).toList();
        }

        if (nonFavRestaurants.isNotEmpty) {
          var recommendedRest = nonFavRestaurants[random.nextInt(nonFavRestaurants.length)];
          var restName = recommendedRest['name'] ?? 'un gran lugar';
          var category = recommendedRest['food_type'] ?? 'comida deliciosa';
          
          responseText = "Ya que te gusta probar cosas nuevas, deberías ir a **$restName**.\n¡Se especializan en comida **$category** y te va a encantar!";
        } else {
          responseText = "¡Has probado de todo! No encuentro un restaurante nuevo por ahora. Sigue explorando.";
        }
      } else if (option == "Lo mejor para ti") {
        if (_misFavoritos.isNotEmpty) {
          var randomFav = _misFavoritos[random.nextInt(_misFavoritos.length)];
          var restName = randomFav['restaurants']?['name'] ?? 'ese lugar que te gusta';
          var category = randomFav['restaurants']?['food_type'] ?? 'tu comida preferida';
          
          responseText = "Basado en tus favoritos, sé que te encanta la comida $category.\n¡Deberías ir de nuevo a **$restName**, es una apuesta segura para tu antojo!";
        } else {
          responseText = "Aún no tienes favoritos para recomendarte lo mejor, ¡agrega algunos primero!";
        }
      } else {
        responseText = "¡Tus deseos son órdenes! Ve a la sección de búsqueda y encuentra tu próximo antojo.";
      }
    }

    if (mounted) {
      setState(() {
        _messages.add({'sender': 'genie', 'text': responseText});
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
        title: const Text(
          'Genio de los antojos',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.teal.shade100 : Colors.white,
                          border: Border.all(color: isUser ? Colors.teal.shade200 : Colors.grey.shade300),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isUser ? 12 : 2),
                            bottomRight: Radius.circular(isUser ? 2 : 12),
                          ),
                        ),
                        child: Text(
                          msg['text'],
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Opciones de Chat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  )
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: OutlinedButton(
                      onPressed: () => _handleOptionSelected(option),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: const BorderSide(color: Colors.teal),
                        backgroundColor: Colors.teal.shade50,
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}
