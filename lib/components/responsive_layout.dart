import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth:
              450, // Mantiene el tamaño de un celular aunque lo abras en PC
        ),
        child: child,
      ),
    );
  }
}
