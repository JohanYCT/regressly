import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(RegresslyApp());
}

class RegresslyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Regressly',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}