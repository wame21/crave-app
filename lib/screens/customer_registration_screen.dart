import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/api_services.dart'; // <-- Asegúrate de que la ruta sea correcta

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  // Controladores para leer lo que escribe el usuario
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  void _registrarCliente() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validar que no haya campos vacíos
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Llena todos los campos loco!'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // 2. Validar que las contraseñas coincidan
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Las contraseñas no coinciden w.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // 3. Todo en orden, prendemos la ruedita y le pegamos al servidor
    setState(() => _isLoading = true);

    // Mandamos el rol de 'Client' directo
    final result = await ApiService.registerUser(
      name,
      email,
      password,
      'Client',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 4. Manejamos la respuesta
    if (result['success']) {
      // ---> AQUÍ ESTÁ LA MAGIA QUE FALTABA <---
      // Guardamos el gafete de sesión antes de mandarlo al Home
      final userId = result['user']['id_user'].toString();
      await ApiService.guardarSesion(userId);

      // Cuenta creada, lo mandamos directo al Home y borramos el historial
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      // Error (ej. correo ya registrado)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al registrar'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crave',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Crea tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),

              // Campo: Nombre de usuario
              const Text(
                'Nombre de usuario',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField('Nombre', _nameController),
              const SizedBox(height: 20),

              // Campo: Correo
              const Text(
                'Correo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                'correo@gmail.com',
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Campo: Contraseña
              const Text(
                'Contraseña',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                '********',
                _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              // Campo: Confirmar contraseña
              const Text(
                'Confirmar contraseña',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                '********',
                _confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 40),

              // Botón Registrarme
              ElevatedButton(
                onPressed: _isLoading ? null : _registrarCliente, // Dinámico
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Registrarme',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Texto de términos
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Al hacer clic en continuar, aceptas nuestros ',
                    ),
                    TextSpan(
                      text: 'Términos de\nservicio',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(text: ' y '),
                    TextSpan(
                      text: 'Política de privacidad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Se actualizó la función para recibir el TextEditingController
  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
    );
  }
}
