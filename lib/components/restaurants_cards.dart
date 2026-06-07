import 'package:flutter/material.dart';
import '../screens/restaurant_detail_screen.dart';

class RestaurantCard extends StatelessWidget {
  final String id; // <-- 1. Agregamos el ID aquí
  final String name;
  final String category;
  final Color imageColor;
  final double width;

  const RestaurantCard({
    super.key,
    required this.id, // <-- 2. Lo hacemos obligatorio
    required this.name,
    required this.category,
    required this.imageColor,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(
              // 3. ¡Aquí está la magia! Le pasamos los datos a la pantalla
              restaurantId: id,
              restaurantName: name,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: width,
                height: width,
                decoration: BoxDecoration(
                  color: imageColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
