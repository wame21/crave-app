import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

class EditRestaurantScreen extends StatefulWidget {
  const EditRestaurantScreen({super.key});

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  RestaurantModel? _restaurant;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _openingHoursController = TextEditingController();

  String _selectedCategory = 'Mexicana';
  final List<String> _categorias = ['Mexicana', 'Italiana', 'Sushi', 'Hamburguesas', 'Café', 'Pizza', 'Alitas', 'Mariscos', 'China', 'Tacos'];

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final restaurant = await RestaurantService.getMyRestaurant();
      setState(() {
        _restaurant = restaurant;
        _nameController.text = restaurant.name;
        _phoneController.text = restaurant.phone ?? '';
        _addressController.text = restaurant.address ?? '';
        _openingHoursController.text = restaurant.openingHours ?? '';
        
        if (restaurant.foodType != null && _categorias.contains(restaurant.foodType)) {
          _selectedCategory = restaurant.foodType!;
        }

        if (restaurant.socialMedia != null) {
          try {
            Map<String, dynamic> sm;
            if (restaurant.socialMedia is String) {
              sm = jsonDecode(restaurant.socialMedia);
            } else {
              sm = restaurant.socialMedia;
            }
            _instagramController.text = sm['instagram'] ?? '';
            _facebookController.text = sm['facebook'] ?? '';
          } catch (_) {}
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRestaurant() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es obligatorio')));
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final sm = jsonEncode({
        'instagram': _instagramController.text.trim(),
        'facebook': _facebookController.text.trim(),
      });

      await RestaurantService.updateRestaurant(_restaurant!.idRestaurant, {
        'name': name,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'opening_hours': _openingHoursController.text.trim(),
        'food_type': _selectedCategory,
        'social_media': sm,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurante guardado con éxito')));
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
    _phoneController.dispose();
    _addressController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_errorMessage != null && _restaurant == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Botón X y Título)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
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
                        'Editar Restaurante',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 36), 
                  ],
                ),
              ),

              // 2. Banner y Logo con botones de editar
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(color: Colors.teal.shade300),
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant_menu, color: Colors.white54, size: 60),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 16,
                    child: _buildEditIconButton(),
                  ),
                  Positioned(
                    bottom: -40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.shade100,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _restaurant!.name.isNotEmpty ? _restaurant!.name[0].toUpperCase() : 'R',
                        style: const TextStyle(fontSize: 40, color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    right: MediaQuery.of(context).size.width / 2 - 60, 
                    child: _buildEditIconButton(),
                  ),
                ],
              ),
              const SizedBox(height: 60), 

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),

              // 3. Formulario (Text fields)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormRow('Restaurante', _nameController),
                    _buildFormRow('Teléfono', _phoneController),
                    _buildFormRow('Dirección', _addressController),
                    
                    const Divider(color: Colors.black, thickness: 1),

                    _buildFormRow('Instagram', _instagramController),
                    _buildFormRow('Facebook', _facebookController),
                    const SizedBox(height: 16),

                    // 4. Horario
                    const Text('Horario de apertura (ej. L-V 08:00-19:00)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _openingHoursController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 8),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. Categoría principal (COMBO BOX REAL)
                    const Text('Categoría principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black87),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      items: _categorias.map((String categoria) {
                        return DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria, style: const TextStyle(fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          if (newValue != null) {
                            _selectedCategory = newValue;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 40),

                    // 7. Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _saveRestaurant,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.black87),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text(
                                'Guardar',
                                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNCIONES AYUDANTES --- //

  Widget _buildEditIconButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.edit, size: 20, color: Colors.black),
    );
  }

  Widget _buildFormRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 100, 
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.only(bottom: 4),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}