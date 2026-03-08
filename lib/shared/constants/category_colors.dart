import 'package:flutter/material.dart';

Color colorForCategory(String key) {
  switch (key) {
    case 'comida':
      return Colors.orange;
    case 'hogar':
      return Colors.blue;
    case 'mascotas':
      return Colors.purple;
    case 'internet':
      return Colors.teal;
    case 'luz':
      return Colors.amber;
    case 'agua':
      return Colors.cyan;
    case 'vestimenta':
      return Colors.pink;
    case 'combustible':
      return Colors.red;
    case 'mercado':
      return Colors.green;
    case 'gasto_extra':
      return Colors.brown;
    default:
      return Colors.grey;
  }
}