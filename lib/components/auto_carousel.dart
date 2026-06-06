import 'package:flutter/material.dart';
import 'dart:async';

class AutoCarouselDestacados extends StatefulWidget {
  const AutoCarouselDestacados({super.key});

  @override
  State<AutoCarouselDestacados> createState() => _AutoCarouselDestacadosState();
}

class _AutoCarouselDestacadosState extends State<AutoCarouselDestacados> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _destacados = [
    {
      'name': 'Doña Licha',
      'bgColor': Colors.teal.shade100,
      'textColor': Colors.teal,
    },
    {
      'name': 'Burger King',
      'bgColor': Colors.orange.shade100,
      'textColor': Colors.orange,
    },
    {
      'name': 'Sushi Sohoc',
      'bgColor': Colors.red.shade100,
      'textColor': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _destacados.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
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
      itemCount: _destacados.length,
      itemBuilder: (context, index) {
        final item = _destacados[index];
        return Container(
          decoration: BoxDecoration(
            color: item['bgColor'],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '${item['name']}\n(Imagen aquí)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: item['textColor'],
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
