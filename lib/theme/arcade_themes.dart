import 'package:flutter/material.dart';

/// Theme, disc-style and board-accent catalog for Four in a Row.
///
/// Every theme stays inside the Tabletop Arcade Skeuomorph material world
/// (real wood cabinets, brushed/chrome/brass/copper metal, cream plastic,
/// warm tungsten light) — the variety comes from different woods, metal
/// accents and disc colorways. No neon, no glow, no cyberpunk.
class F4ArcadeThemeDef {
  final String id;
  final String name;
  final Color woodDark; // screen backdrop
  final Color woodMid; // cabinet plate
  final Color woodDeep; // deepest recess
  final Color accent; // metal accent (chrome / brass / copper …)
  final Color accentLight;
  final Color accentDark;
  final Color ivory; // cream plastic
  final Color felt; // board bed color
  final Color redDisc; // player 1 disc
  final Color amberDisc; // player 2 disc

  const F4ArcadeThemeDef({
    required this.id,
    required this.name,
    required this.woodDark,
    required this.woodMid,
    required this.woodDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ivory,
    required this.felt,
    required this.redDisc,
    required this.amberDisc,
  });
}

class F4ArcadeThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'walnut',
    'oak',
    'mahogany',
    'ebony',
  ];

  static bool isProTheme(String id) => !freeThemeIds.contains(id);

  static const List<F4ArcadeThemeDef> all = [
    F4ArcadeThemeDef(
      id: 'walnut',
      name: 'Dark Walnut',
      woodDark: Color(0xFF1D100B),
      woodMid: Color(0xFF4A2E18),
      woodDeep: Color(0xFF0E0705),
      accent: Color(0xFF8C9095),
      accentLight: Color(0xFFC9CDD2),
      accentDark: Color(0xFF565A5F),
      ivory: Color(0xFFF4EDE2),
      felt: Color(0xFF2E4030),
      redDisc: Color(0xFFD63426),
      amberDisc: Color(0xFFF49F1C),
    ),
    F4ArcadeThemeDef(
      id: 'oak',
      name: 'Honey Oak',
      woodDark: Color(0xFF4A2E14),
      woodMid: Color(0xFF7A5228),
      woodDeep: Color(0xFF2A1808),
      accent: Color(0xFF9A8A76),
      accentLight: Color(0xFFD4C6B2),
      accentDark: Color(0xFF5E544A),
      ivory: Color(0xFFFAF3E6),
      felt: Color(0xFF3A5238),
      redDisc: Color(0xFFC22E20),
      amberDisc: Color(0xFFE8960F),
    ),
    F4ArcadeThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      woodDark: Color(0xFF3A140D),
      woodMid: Color(0xFF64281A),
      woodDeep: Color(0xFF1F0A06),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF6EBDA),
      felt: Color(0xFF47302A),
      redDisc: Color(0xFFD63426),
      amberDisc: Color(0xFFF0A020),
    ),
    F4ArcadeThemeDef(
      id: 'ebony',
      name: 'Midnight Ebony',
      woodDark: Color(0xFF0E0C0A),
      woodMid: Color(0xFF26221E),
      woodDeep: Color(0xFF050404),
      accent: Color(0xFFB8BDC4),
      accentLight: Color(0xFFE4E8EE),
      accentDark: Color(0xFF6E747C),
      ivory: Color(0xFFF2EEE4),
      felt: Color(0xFF232A35),
      redDisc: Color(0xFFE04030),
      amberDisc: Color(0xFFFFB020),
    ),
    F4ArcadeThemeDef(
      id: 'cherry',
      name: 'Cherrywood',
      woodDark: Color(0xFF3F1510),
      woodMid: Color(0xFF6E2A1C),
      woodDeep: Color(0xFF200A06),
      accent: Color(0xFFB0713A),
      accentLight: Color(0xFFDBA76A),
      accentDark: Color(0xFF74471F),
      ivory: Color(0xFFF7EDDC),
      felt: Color(0xFF503225),
      redDisc: Color(0xFFD42A1E),
      amberDisc: Color(0xFFF2A41C),
    ),
    F4ArcadeThemeDef(
      id: 'maple',
      name: 'Maple & Cream',
      woodDark: Color(0xFF7A5A34),
      woodMid: Color(0xFFA8845A),
      woodDeep: Color(0xFF4A3418),
      accent: Color(0xFF8C9095),
      accentLight: Color(0xFFC9CDD2),
      accentDark: Color(0xFF565A5F),
      ivory: Color(0xFFFFF8EC),
      felt: Color(0xFF4A5A40),
      redDisc: Color(0xFFC62E22),
      amberDisc: Color(0xFFEF9E14),
    ),
    F4ArcadeThemeDef(
      id: 'rosewood',
      name: 'Rosewood Club',
      woodDark: Color(0xFF2E0F0E),
      woodMid: Color(0xFF54201C),
      woodDeep: Color(0xFF160706),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFF0D98A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF5EAD6),
      felt: Color(0xFF3E2A3A),
      redDisc: Color(0xFFD83A2A),
      amberDisc: Color(0xFFF5A818),
    ),
    F4ArcadeThemeDef(
      id: 'walnutbrass',
      name: 'Brassworks',
      woodDark: Color(0xFF241209),
      woodMid: Color(0xFF4E2F16),
      woodDeep: Color(0xFF120905),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFF2DA8E),
      accentDark: Color(0xFF7E6418),
      ivory: Color(0xFFF4EDE2),
      felt: Color(0xFF2B2B22),
      redDisc: Color(0xFFD63426),
      amberDisc: Color(0xFFFFC23E),
    ),
    F4ArcadeThemeDef(
      id: 'copper',
      name: 'Copper Mill',
      woodDark: Color(0xFF2A150C),
      woodMid: Color(0xFF52301A),
      woodDeep: Color(0xFF150A05),
      accent: Color(0xFFB0713A),
      accentLight: Color(0xFFE0A96E),
      accentDark: Color(0xFF6E4420),
      ivory: Color(0xFFF6EEE0),
      felt: Color(0xFF40302A),
      redDisc: Color(0xFFD0402A),
      amberDisc: Color(0xFFF49F1C),
    ),
    F4ArcadeThemeDef(
      id: 'forest',
      name: 'Forest Lodge',
      woodDark: Color(0xFF1E2A16),
      woodMid: Color(0xFF3A4A28),
      woodDeep: Color(0xFF0E1408),
      accent: Color(0xFF9AA08C),
      accentLight: Color(0xFFCCD2BE),
      accentDark: Color(0xFF5E6452),
      ivory: Color(0xFFF2F0E2),
      felt: Color(0xFF1E3A24),
      redDisc: Color(0xFFD63426),
      amberDisc: Color(0xFFF2A41C),
    ),
    F4ArcadeThemeDef(
      id: 'harbor',
      name: 'Old Harbor',
      woodDark: Color(0xFF14202A),
      woodMid: Color(0xFF2A3E4E),
      woodDeep: Color(0xFF081016),
      accent: Color(0xFF8FA3B0),
      accentLight: Color(0xFFC4D3DE),
      accentDark: Color(0xFF56636E),
      ivory: Color(0xFFEEF0E8),
      felt: Color(0xFF1E3A4A),
      redDisc: Color(0xFFD84A30),
      amberDisc: Color(0xFFF0A41E),
    ),
    F4ArcadeThemeDef(
      id: 'bakery',
      name: 'Bakery Morning',
      woodDark: Color(0xFF5A3A20),
      woodMid: Color(0xFF8A5E36),
      woodDeep: Color(0xFF38220F),
      accent: Color(0xFFB08A5A),
      accentLight: Color(0xFFDCBB8E),
      accentDark: Color(0xFF6E5434),
      ivory: Color(0xFFFFF6E8),
      felt: Color(0xFF6A5238),
      redDisc: Color(0xFFCE3A26),
      amberDisc: Color(0xFFF6AC22),
    ),
    F4ArcadeThemeDef(
      id: 'apothecary',
      name: 'Apothecary',
      woodDark: Color(0xFF201410),
      woodMid: Color(0xFF3E2C22),
      woodDeep: Color(0xFF0F0906),
      accent: Color(0xFF7E8A6A),
      accentLight: Color(0xFFB2BC9E),
      accentDark: Color(0xFF4E563E),
      ivory: Color(0xFFF0EAD8),
      felt: Color(0xFF2E3A2A),
      redDisc: Color(0xFFC93A24),
      amberDisc: Color(0xFFE8A020),
    ),
    F4ArcadeThemeDef(
      id: 'carnival',
      name: 'Carnival Booth',
      woodDark: Color(0xFF331410),
      woodMid: Color(0xFF5E2A1E),
      woodDeep: Color(0xFF180807),
      accent: Color(0xFFD4A017),
      accentLight: Color(0xFFF2CE6E),
      accentDark: Color(0xFF8A6410),
      ivory: Color(0xFFF8F0DC),
      felt: Color(0xFF5E2E24),
      redDisc: Color(0xFFDE3A24),
      amberDisc: Color(0xFFFFB41E),
    ),
  ];

  static F4ArcadeThemeDef byId(String id, {F4ArcadeThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

// ---------------------------------------------------------------------------
/// Disc styles — physical materials for the game discs. First 3 are FREE.
class DiscStyles {
  static const List<String> names = [
    'Classic Acrylic',
    'Polished Wood',
    'Glass Marble',
    'Marbled Stone',
    'Brass Coin',
    'Candy Swirl',
    'Leather',
    'Ivory Bone',
    'Poker Chip',
    'Hammered Steel',
  ];

  static const List<String> freeNames = [
    'Classic Acrylic',
    'Polished Wood',
    'Glass Marble',
  ];

  static bool isPro(int index) => !freeNames.contains(names[index.clamp(0, names.length - 1)]);
}

// ---------------------------------------------------------------------------
/// Board frame accents — the metal/wood frame of the grid toy.
/// First 2 are FREE.
class BoardAccents {
  static const List<String> names = [
    'Brushed Chrome',
    'Dark Walnut',
    'Polished Brass',
    'Aged Copper',
    'Black Iron',
    'Cream Enamel',
  ];

  static const List<String> freeNames = [
    'Brushed Chrome',
    'Dark Walnut',
  ];

  static bool isPro(int index) => !freeNames.contains(names[index.clamp(0, names.length - 1)]);

  /// Frame colors for an accent index: [light, mid, dark].
  static List<Color> colors(int index, F4ArcadeThemeDef theme) {
    switch (names[index.clamp(0, names.length - 1)]) {
      case 'Brushed Chrome':
        return [const Color(0xFFC9CDD2), const Color(0xFF8C9095), const Color(0xFF565A5F)];
      case 'Dark Walnut':
        return [const Color(0xFF4A2E18), const Color(0xFF2E1A0C), const Color(0xFF150C06)];
      case 'Polished Brass':
        return [const Color(0xFFF2DA8E), const Color(0xFFC9A227), const Color(0xFF7E6418)];
      case 'Aged Copper':
        return [const Color(0xFFE0A96E), const Color(0xFFB0713A), const Color(0xFF6E4420)];
      case 'Black Iron':
        return [const Color(0xFF4A4A4E), const Color(0xFF26262A), const Color(0xFF0E0E10)];
      case 'Cream Enamel':
        return [const Color(0xFFFFFBF3), const Color(0xFFF4EDE2), const Color(0xFFC9BCA8)];
      default:
        return [theme.accentLight, theme.accent, theme.accentDark];
    }
  }
}
