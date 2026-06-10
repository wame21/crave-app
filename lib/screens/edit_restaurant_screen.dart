import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_services.dart';

class EditRestaurantScreen extends StatefulWidget {
  const EditRestaurantScreen({super.key});

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  bool _isLoading = true;
  String? _userId;

  // Controladores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _igController = TextEditingController();
  final TextEditingController _fbController = TextEditingController();

  // --- NUEVAS VARIABLES DE HORARIO ---
  TimeOfDay? _horaApertura;
  TimeOfDay? _horaCierre;

  // Aquí controlamos qué días seleccionas (Lu a Do)
  List<bool> selectedDays = [true, true, true, true, true, true, false];

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
  void initState() {
    super.initState();
    _cargarDatosInteligentes();
  }

  Future<void> _cargarDatosInteligentes() async {
    try {
      final userId = await ApiService.obtenerUsuarioId();
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final perfil = await ApiService.obtenerPerfil(userId);
      final miRestaurante = await ApiService.obtenerMiRestaurante(userId);

      if (mounted) {
        setState(() {
          _userId = userId;

          if (miRestaurante != null) {
            _nameController.text = miRestaurante['name'] ?? '';
            _addressController.text = miRestaurante['address'] ?? '';
            if (miRestaurante['food_type'] != null &&
                _categorias.contains(miRestaurante['food_type'])) {
              _selectedCategory = miRestaurante['food_type'];
            }
          } else {
            _nameController.text = perfil?['profile_name'] ?? '';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al conectar w.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- FUNCIÓN DEL RELOJ ---
  Future<void> _seleccionarHora(bool esApertura) async {
    final TimeOfDay? seleccion = await showTimePicker(
      context: context,
      initialTime: esApertura
          ? (_horaApertura ?? const TimeOfDay(hour: 8, minute: 0))
          : (_horaCierre ?? const TimeOfDay(hour: 20, minute: 0)),
    );

    if (seleccion != null && mounted) {
      setState(() {
        if (esApertura) {
          _horaApertura = seleccion;
        } else {
          _horaCierre = seleccion;
        }
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);

    // Si después agregas estas columnas en tu Supabase, aquí ya las tienes empaquetadas:
    /*
    String diasActivos = '';
    final nombresDias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) diasActivos += '${nombresDias[i]} ';
    }
    String horaAperturaTexto = _horaApertura?.format(context) ?? 'No definida';
    String horaCierreTexto = _horaCierre?.format(context) ?? 'No definida';
    */

    final datos = {
      'id_user': _userId,
      'name': _nameController.text.trim(),
      'description': '',
      'address': _addressController.text.trim(),
      'food_type': _selectedCategory,
    };

    final exito = await ApiService.guardarDatosRestaurante(datos);

    if (mounted) {
      setState(() => _isLoading = false);

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Datos guardados al cien!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un pedo al guardar w.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _igController.dispose();
    _fbController.dispose();
    super.dispose();
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
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
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

                    // 2. Banner y Logo
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.pink.shade200,
                          ),
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

                    // 3. Formulario
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormRow(
                            'Restaurante',
                            _nameController,
                            hint: 'Nombre de tu negocio',
                          ),
                          _buildFormRow(
                            'Telefono',
                            _phoneController,
                            hint: '687 999 9999',
                          ),

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
                                    child: Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Icon(
                                            Icons.map_outlined,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _addressController,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.black, thickness: 1),

                          _buildFormRow(
                            'Instagram',
                            _igController,
                            hint: '@TuUsuario',
                          ),
                          _buildFormRow(
                            'Facebook',
                            _fbController,
                            hint: '@TuUsuario',
                          ),
                          const SizedBox(height: 16),

                          // --- HORARIOS ---
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
                              // BOTONES REALES DE HORA
                              Expanded(
                                child: _buildTimePickerButton(
                                  'Apertura',
                                  _horaApertura,
                                  true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimePickerButton(
                                  'Cierre',
                                  _horaCierre,
                                  false,
                                ),
                              ),
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

                          // Categoría
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
                                borderSide: const BorderSide(
                                  color: Colors.black87,
                                ),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
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

                          // Imágenes
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
                                {
                                  'text': 'Menú 1',
                                  'color': Colors.orange.shade200,
                                },
                                {
                                  'text': 'Menú 2',
                                  'color': Colors.orange.shade300,
                                },
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

                          // Botón Guardar
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _guardarCambios,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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

  // --- FUNCIONES AYUDANTES ---

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

  Widget _buildFormRow(
    String label,
    TextEditingController controller, {
    String hint = '',
  }) {
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
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 4),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- EL BOTÓN DE HORA REAL ---
  Widget _buildTimePickerButton(
    String titulo,
    TimeOfDay? horaGuardada,
    bool esApertura,
  ) {
    // Convierte la hora a texto (ej. 8:00 AM) o muestra el título si está vacío
    String textoAMostrar = horaGuardada != null
        ? horaGuardada.format(context)
        : titulo;

    return InkWell(
      onTap: () => _seleccionarHora(esApertura),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87),
          borderRadius: BorderRadius.circular(8),
          color: horaGuardada != null
              ? Colors.teal.shade50
              : Colors.white, // Cambia de color si ya seleccionaste
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              textoAMostrar,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Los botones de días cambian su estado en el array `selectedDays` automáticamente
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
          color: isSelected
              ? Colors.teal.shade100
              : Colors.white, // Color más vivo para los activos
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
// WIDGET: Carrusel Editable con Alerta de Borrado
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
              onPressed: () => Navigator.pop(context),
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
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Imagen borrada')));
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
      onPageChanged: (int page) => setState(() => _currentPage = page),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Stack(
          children: [
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
                  padding: const EdgeInsets.all(8),
                  onPressed: () {},
                ),
              ),
            ),
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
                  onPressed: () => _showDeleteConfirmation(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
