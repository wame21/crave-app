import 'package:flutter/material.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';
import 'components/responsive_layout.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crave App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Aseguramos que el fondo sea blanco
      ),
      
      // AQUÍ ESTÁ LA MAGIA GLOBAL:
      // El 'builder' intercepta cualquier pantalla antes de dibujarla 
      // y la mete a fuerza en nuestro ResponsiveLayout.
      builder: (context, child) {
        return ResponsiveLayout(
          child: child!, // 'child' es la pantalla en la que estés en ese momento
        );
      },
      
      // Ya puedes poner tu HomeScreen normalito aquí
      home: const LoginScreen(),
    );
  }
}