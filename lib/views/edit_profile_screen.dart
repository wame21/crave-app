import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                          constraints: const BoxConstraints(), // Reduce el tamaño por defecto del IconButton
                          onPressed: () {
                            Navigator.pop(context); // Esto te regresa a la pantalla anterior
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
                      const SizedBox(width: 36), // Espacio en blanco para centrar el título perfectamente
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Foto de Perfil con el ícono de Editar apilado
                  Stack(
                    alignment: Alignment.bottomRight, // Alinea el contenido hijo abajo a la derecha
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                          color: Colors.yellow.shade200,
                        ),
                        child: const Icon(Icons.person, size: 80, color: Colors.black54),
                      ),
                      // Ícono de lápiz en un cuadrito blanco
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(4), // Cuadradito con bordes un poco redondeados
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
                          initialValue: 'Pedro Sanchez', // Valor por defecto
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
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Aquí iría la lógica para guardar en la base de datos
                        Navigator.pop(context); // Y luego te regresa a la pantalla anterior
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
      // Mantenemos el BottomNav
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }
}