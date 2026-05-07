import 'package:flutter/material.dart';
import 'views/login_screen.dart'; // Importamos tu nueva pantalla

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita la etiqueta de "DEBUG"
      title: 'Crave App',
      theme: ThemeData(
        fontFamily: 'Inter', // Aquí puedes poner la fuente que usaste en Figma después
      ),
      home: const LoginScreen(), // Le decimos que arranque en tu diseño
    );
  }
}