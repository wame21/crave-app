import 'package:flutter/material.dart';
import 'dart:io'; // Necesario para manejar archivos en celular
import 'package:flutter/foundation.dart'; // <-- NUEVO: Para saber si estamos en Chrome (Web)
import 'package:image_picker/image_picker.dart';
import '../components/custom_bottom_nav.dart';
import '../services/api_services.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;
  String? _userId;

  // Cambiamos File por XFile para que no crashee en Chrome
  XFile? _imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarPerfilUsuario();
  }

  void _cargarPerfilUsuario() async {
    final id = await ApiService.obtenerUsuarioId();
    if (id != null) {
      // ---> MAGIA AQUÍ: Jalamos el perfil real de tu base de datos <---
      final perfil = await ApiService.obtenerPerfil(id);

      setState(() {
        _userId = id;
        if (perfil != null) {
          // Si encontró el perfil, ponemos tu nombre real en la caja de texto
          _nameController.text = perfil['profile_name'] ?? 'Usuario';
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNCIÓN PARA ABRIR LA GALERÍA ---
  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        // Guardamos el archivo compatible con Web y Móvil
        _imagenSeleccionada = imagen;
      });
    }
  }

  void _guardarCambios() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);

    bool exitoFoto = true;

    // Si el usuario seleccionó una foto nueva, la mandamos al servidor
    if (_imagenSeleccionada != null) {
      exitoFoto = await ApiService.actualizarFotoPerfil(
        _userId!,
        _imagenSeleccionada!,
      );
    }

    // Aquí después agregaremos la actualización del nombre si quieres

    setState(() => _isLoading = false);

    if (mounted) {
      if (exitoFoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Perfil actualizado con éxito!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context); // Lo regresamos a su perfil
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hubo un error al actualizar el perfil w'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
            : Column(
                children: [
                  Container(
                    color: Colors.grey.shade200,
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 40,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.black,
                                  size: 24,
                                ),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Editar Perfil',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 36),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // --- FOTO DE PERFIL DINÁMICA ---
                        GestureDetector(
                          onTap: _seleccionarFoto,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  color: Colors.yellow.shade200,
                                  // ---> PARCHE WEB AQUÍ <---
                                  image: _imagenSeleccionada != null
                                      ? DecorationImage(
                                          image: kIsWeb
                                              ? NetworkImage(
                                                      _imagenSeleccionada!.path,
                                                    )
                                                    as ImageProvider
                                              : FileImage(
                                                  File(
                                                    _imagenSeleccionada!.path,
                                                  ),
                                                ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _imagenSeleccionada == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.black54,
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Nombre: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(bottom: 8),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _guardarCambios,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.black87),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Guardar',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }
}
