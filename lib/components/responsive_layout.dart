import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Este es el color que se verá en los "espacios vacíos" en PC
      color: Colors.grey.shade100, 
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800, // Ancho máximo tipo celular (puedes ajustarlo)
          ),
          // ClipRect asegura que si algo se pasa de los 500px, se corte y no ensucie el fondo
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}