import 'package:flutter/material.dart';

Color hexToColor(String hex) {
  hex = hex.replaceAll("#", "");
  return Color(int.parse("FF$hex", radix: 16));
}

IconData iconFromString(String name) {
  switch (name) {
    case "calculate":
      return Icons.calculate_rounded;
    case "science":
      return Icons.science_rounded;
    case "eco":
      return Icons.eco_rounded;
    default:
      return Icons.school_rounded;
  }
}
