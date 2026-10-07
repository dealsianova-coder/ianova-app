import 'package:flutter/material.dart';

const _namedColors = <String, Color>{
  'black': Color(0xFF111111),
  'white': Color(0xFFFFFFFF),
  'red': Color(0xFFE5173F),
  'blue': Color(0xFF2F6FED),
  'navy': Color(0xFF0B1F3F),
  'green': Color(0xFF2FA84F),
  'pink': Color(0xFFF472B6),
  'purple': Color(0xFF8B5CF6),
  'yellow': Color(0xFFFFD60A),
  'orange': Color(0xFFFF8A00),
  'grey': Color(0xFF9AA0AE),
  'gray': Color(0xFF9AA0AE),
  'brown': Color(0xFF8B5E3C),
  'beige': Color(0xFFE8D8C0),
  'cream': Color(0xFFF5EBDD),
  'gold': Color(0xFFD4AF37),
  'silver': Color(0xFFC0C4CC),
  'maroon': Color(0xFF7B1E3A),
  'teal': Color(0xFF14B8A6),
  'khaki': Color(0xFFC3B091),
};

/// Swatch color for a name like "Red", or null when the name is not known.
Color? colorFromName(String name) => _namedColors[name.trim().toLowerCase()];
