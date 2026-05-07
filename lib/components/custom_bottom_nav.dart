import 'package:flutter/material.dart';
import '../views/home_screen.dart';
import '../views/profile_screen.dart';
import '../views/genie_screen.dart';
import '../views/search_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex; // Para saber qué ícono iluminar

  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      onTap: (index) {
        // Evitamos navegar si ya estamos en esa pantalla
        if (index == currentIndex) return;

        // Lógica de navegación
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim1, anim2) => const HomeScreen(),
              transitionDuration: Duration.zero,
            ),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim1, anim2) => const SearchScreen(),
              transitionDuration: Duration.zero,
            ),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim1, anim2) => const GenieScreen(),
              transitionDuration: Duration.zero,
            ),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim1, anim2) => const ProfileScreen(),
              transitionDuration: Duration.zero,
            ),
          );
        }

        // Aquí irás agregando el index 2 (Regalos) e index 3 (Perfil)
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 30),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search, size: 30),
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome, size: 30),
          label: 'IA',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: 30),
          label: 'Perfil',
        ),
      ],
    );
  }
}
