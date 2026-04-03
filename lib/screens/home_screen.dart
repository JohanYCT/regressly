import 'package:flutter/material.dart';
import 'registro_screen.dart';
import 'analisis_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    RegistroScreen(),
    AnalisisScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Registro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Análisis',
          ),
        ],
      ),
    );
  }
}