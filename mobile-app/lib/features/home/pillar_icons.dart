import 'package:flutter/material.dart';

/// Icon choices for admin-editable "pillar" tiles on the public landing
/// page. Keys are stored in the backend (`org.pillars_json`) so they must
/// stay stable — add new entries, never rename/remove existing keys.
const pillarIconChoices = <String, IconData>{
  'book': Icons.menu_book_rounded,
  'heart': Icons.favorite_rounded,
  'hands': Icons.volunteer_activism_rounded,
  'mosque': Icons.mosque_rounded,
  'school': Icons.school_rounded,
  'people': Icons.groups_rounded,
  'star': Icons.star_rounded,
  'shield': Icons.shield_rounded,
};

IconData pillarIcon(String key) => pillarIconChoices[key] ?? Icons.menu_book_rounded;
