import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await UserService.getMyProfile();
      setState(() {
        _profile = profile;
        _nameController.text = profile.profileName ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre no puede estar vacío')));
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await UserService.updateProfile({
        'profile_name': name,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil guardado con éxito')));
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _errorMessage != null && _profile == null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    children: [
                      // Sección Superior (Fondo gris clarito)
                      Container(
                        color: Colors.grey.shade200,
                        padding: const EdgeInsets.only(top: 16, bottom: 40, left: 24, right: 24),
                        child: Column(
                          children: [
                            // Fila superior con el botón "X" y el título
                            Row(
                              children: [
                                // Botón circular con la X
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.black, size: 24),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(), 
                                    onPressed: () {
                                      Navigator.pop(context); 
                                    },
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Editar Perfil',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 36), 
                              ],
                            ),
                            const SizedBox(height: 30),

                            // Foto de Perfil con el ícono de Editar apilado
                            Stack(
                              alignment: Alignment.bottomRight, 
                              children: [
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                    color: Colors.yellow.shade200,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _profile?.profileName?.isNotEmpty == true ? _profile!.profileName![0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 60, color: Colors.black54, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Ícono de lápiz en un cuadrito blanco
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black, width: 1.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.edit, size: 20, color: Colors.black),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),

                            // Fila del Nombre y la caja de texto
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Nombre: ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(bottom: 8),
                                      // Solo le dejamos la línea de abajo
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Sección Inferior (Fondo blanco con el botón Guardar)
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              children: [
                                if (_errorMessage != null) ...[
                                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 16),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.black87),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                        : const Text(
                                            'Guardar',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
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