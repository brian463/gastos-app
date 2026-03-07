import 'package:flutter/material.dart';

const Map<String, Color> kCategoryColors = {
  'comida': Colors.orange,
  'hogar': Colors.blue,
  'mascotas': Colors.purple,
  'internet': Colors.teal,
  'luz': Colors.amber,
  'agua': Colors.cyan,
  'vestimenta': Colors.pink,
  'gusto_extra': Colors.red,
};

Color colorForCategory(String c) => kCategoryColors[c] ?? Colors.grey;