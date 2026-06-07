import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';

class GenieScreen extends StatelessWidget {
  const GenieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Genio de los antojos',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Quita la flecha de regreso por defecto
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área donde aparecerán los mensajes del chat
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Burbuja de chat del Genio
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                          bottomLeft: Radius.circular(
                            2,
                          ), // El "pico" de la burbuja
                        ),
                      ),
                      child: const Text(
                        '¿Que se te antoja\nhoy?',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Caja de Input interactiva en la parte inferior
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Campo para escribir
                    const TextField(
                      decoration: InputDecoration(
                        hintText: '....',
                        hintStyle: TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines:
                          3, // Permite que la caja crezca si escriben mucho
                      minLines: 1,
                    ),
                    // Fila de herramientas e ícono de enviar
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        right: 8.0,
                        bottom: 8.0,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.image_outlined,
                              color: Colors.black87,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.mic_none,
                              color: Colors.black87,
                            ),
                            onPressed: () {},
                          ),
                          const Spacer(), // Empuja el botón de enviar hacia la derecha
                          // Botón circular de enviar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_upward,
                                color: Colors.black45,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Mantenemos la barra de navegación sincronizada en el índice 2
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}
