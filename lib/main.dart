import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import '../components/responsive_layout.dart';

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
        scaffoldBackgroundColor: Colors.white,
      ),

      builder: (context, child) {
        return ResponsiveLayout(child: child!);
      },
      home: const LoginScreen(),
    );
  }
}
