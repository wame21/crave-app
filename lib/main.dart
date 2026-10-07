import 'package:flutter/material.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';
import 'components/responsive_layout.dart';
import 'di.dart';
import 'services/auth_service.dart';

/// Navegador de la app, para volver al login cuando la sesión vence.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies(onSessionExpired: showLoginAfterSessionExpired);
  runApp(await createApp());
}

/// Lleva al login, borrando el historial de pantallas, y avisa que la sesión venció.
Future<void> showLoginAfterSessionExpired() async {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
  ScaffoldMessenger.maybeOf(navigator.context)?.showSnackBar(
    const SnackBar(content: Text('Tu sesión expiró. Inicia sesión de nuevo.')),
  );
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
      navigatorKey: navigatorKey,
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
