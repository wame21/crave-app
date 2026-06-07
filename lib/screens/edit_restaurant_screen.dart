import 'package:flutter/material.dart';
import 'dart:async'; // Necesario para el carrusel automático

class EditRestaurantScreen extends StatefulWidget {
  const EditRestaurantScreen({super.key});

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  // Estado para los días de la semana
  List<bool> selectedDays = [true, true, true, true, true, true, false];

  // Estado para el ComboBox de la Categoría
  String _selectedCategory = 'Mexicana';
  final List<String> _categorias = [
    'Mexicana',
    'Italiana',
    'Sushi',
    'Hamburguesas',
    'Café',
    'Pizza',
    'Alitas',
  ];

  @override
  Widget build(BuildContext context) {
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
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 24,
                        ),
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
              ),

              // 2. Banner y Logo con botones de editar
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(color: Colors.pink.shade200),
                    alignment: Alignment.center,
                    child: const Text(
                      'Banner',
                      style: TextStyle(color: Colors.white),
                    ),
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
                      child: const Icon(
                        Icons.restaurant,
                        size: 40,
                        color: Colors.teal,
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

              // 3. Formulario (Text fields)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormRow('Restaurante', 'La cocina de Doña Licha'),
                    _buildFormRow('Telefono', '687 999 9999'),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 100,
                            child: Text(
                              'Dirección',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 35,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black87),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.map_outlined,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.black, thickness: 1),

                    _buildFormRow('Instagram', '@DoñaLicha'),
                    _buildFormRow('Facebook', '@DoñaLicha'),
                    const SizedBox(height: 16),

                    // 4. Horario
                    const Text(
                      'Horario',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildFakeDropdown('Apertura')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildFakeDropdown('Cierre')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDayButton(0, 'Lu'),
                        _buildDayButton(1, 'Ma'),
                        _buildDayButton(2, 'Mi'),
                        _buildDayButton(3, 'Ju'),
                        _buildDayButton(4, 'Vi'),
                        _buildDayButton(5, 'Sa'),
                        _buildDayButton(6, 'Do'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 5. Categoría principal (COMBO BOX REAL)
                    const Text(
                      'Categoría principal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black87),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black,
                      ),
                      items: _categorias.map((String categoria) {
                        return DropdownMenuItem(
                          value: categoria,
                          child: Text(
                            categoria,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
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
                    const SizedBox(height: 24),

                    // 6. Sección de Imágenes (CARRUSELES EDITABLES)
                    const Text(
                      'Menú',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: EditableAutoCarousel(
                        items: [
                          {'text': 'Menú 1', 'color': Colors.orange.shade200},
                          {'text': 'Menú 2', 'color': Colors.orange.shade300},
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Fotos del Restaurante',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: EditableAutoCarousel(
                        items: [
                          {
                            'text': 'Foto Fachada',
                            'color': Colors.blueGrey.shade200,
                          },
                          {
                            'text': 'Foto Interior',
                            'color': Colors.blueGrey.shade300,
                          },
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 7. Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
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
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildFormRow(String label, String initialValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: initialValue,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.only(bottom: 4),
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
    );
  }

  // Botón falso para Apertura y Cierre
  Widget _buildFakeDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(int index, String text) {
    bool isSelected = selectedDays[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDays[index] = !selectedDays[index];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.white,
          border: Border.all(color: Colors.black87),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// =======================================================
// NUEVO WIDGET: Carrusel Editable con Alerta de Borrado
// =======================================================
class EditableAutoCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const EditableAutoCarousel({super.key, required this.items});

  @override
  State<EditableAutoCarousel> createState() => _EditableAutoCarouselState();
}

class _EditableAutoCarouselState extends State<EditableAutoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < widget.items.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Función para mostrar la alerta
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Borrar imagen',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¿Estás seguro de que deseas borrar esta imagen? Esta acción no se puede deshacer.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra la alerta sin hacer nada
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Aquí iría la lógica del back-end para borrar la foto
                Navigator.pop(context); // Cierra la alerta
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Imagen borrada'),
                  ), // Mensajito temporal abajo
                );
              },
              child: const Text(
                'Sí, borrar',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (int page) {
        setState(() {
          _currentPage = page;
        });
      },
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Stack(
          children: [
            // El fondo del carrusel (La imagen)
            Container(
              decoration: BoxDecoration(
                color: item['color'],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                item['text'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),

            // Botón Verde (+) para Agregar
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.black),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(
                    8,
                  ), // Padding ajustado para que sea fácil de tocar
                  onPressed: () {
                    // Lógica para abrir galería y agregar imagen
                  },
                ),
              ),
            ),

            // Botón Rojo (Basura) para Borrar
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade400.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    _showDeleteConfirmation(
                      context,
                    ); // Llama a la alerta de borrado
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
