import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// 1. ESTA ES LA CLASE QUE SE TE HABÍA BORRADO (El "Type")
class EditableAutoCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const EditableAutoCarousel({super.key, required this.items});

  @override
  State<EditableAutoCarousel> createState() => _EditableAutoCarouselState();
}

// 2. ESTE ES EL ESTADO DEL CARRUSEL (El que controla la galería y los tiempos)
class _EditableAutoCarouselState extends State<EditableAutoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final ImagePicker _picker = ImagePicker();
  List<dynamic> misFotos = [];

  @override
  void initState() {
    super.initState();
    misFotos = List.from(widget.items);

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (misFotos.isEmpty) return;
      if (_currentPage < misFotos.length - 1) {
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

  Future<void> _elegirFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.gallery);

    if (foto != null) {
      setState(() {
        misFotos.add({'es_foto_real': true, 'path': foto.path});
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
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
            '¿Estás seguro de que deseas borrar esta imagen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  misFotos.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Sí, borrar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (misFotos.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: IconButton(
          icon: const Icon(Icons.add_a_photo, size: 50, color: Colors.black54),
          onPressed: _elegirFoto,
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (int page) => setState(() => _currentPage = page),
      itemCount: misFotos.length,
      itemBuilder: (context, index) {
        final item = misFotos[index];

        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: item['color'] ?? Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                image: item['es_foto_real'] == true
                    ? DecorationImage(
                        image: FileImage(File(item['path'])),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: item['es_foto_real'] == true
                  ? null
                  : Text(
                      item['text'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                  icon: const Icon(Icons.add, color: Colors.white),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: _elegirFoto,
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
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () => _showDeleteConfirmation(context, index),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
