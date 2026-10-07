import 'package:flutter/material.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';
import 'components/responsive_layout.dart';
import 'di.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(await createApp());
}

/// Crea la app: abre en [HomeScreen] si hay una sesión guardada y en
/// [LoginScreen] si no. Usa el [AuthService] registrado en [getIt].
Future<MyApp> createApp() async {
  final bool isLoggedIn = await getIt<AuthService>().isLoggedIn();
  return MyApp(isLoggedIn: isLoggedIn);
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

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
        return ResponsiveLayout(
          child: child!,
        );
      },
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
