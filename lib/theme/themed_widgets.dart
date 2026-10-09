import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/arcade_themes.dart';
import 'arcade_widgets.dart';

/// Themed widgets: wood backdrop driven by the active theme, physically
/// styled game discs in 10 material variants, and frame accents.

/// Wood cabinet backdrop using the active theme's wood palette + tungsten
/// vignette.
class F4WoodBackdrop extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final Widget child;
  const F4WoodBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WoodPainter(theme: theme),
      child: child,
    );
  }
}

class _WoodPainter extends CustomPainter {
  final F4ArcadeThemeDef theme;
  _WoodPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = theme.woodDark);
    final rand = Random(42);
    for (var i = 0; i < 26; i++) {
      final y = rand.nextDouble() * size.height;
      final light = rand.nextBool();
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (rand.nextDouble() - 0.5) * 30),
        Paint()
          ..color = light
              ? theme.ivory.withValues(alpha: 0.04)
              : const Color(0x14000000)
          ..strokeWidth = 1 + rand.nextDouble() * 3,
      );
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.25,
          colors: const [
            Color(0x004A2410),
            Color(0x55000000),
            Color(0xAA000000),
          ],
          stops: const [0.35, 0.75, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _WoodPainter old) => old.theme != theme;
}

/// Game disc in the active theme's colors and the chosen material style.
/// [player]: 0 = Red side, 1 = Yellow side.
class ThemedDisc extends StatelessWidget {
  final int player;
  final double size;
  final F4ArcadeThemeDef theme;
  final int style;
  final bool highlight;
  const ThemedDisc({
    super.key,
    required this.player,
    required this.size,
    required this.theme,
    this.style = 0,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = player == 0 ? theme.redDisc : theme.amberDisc;
    return CustomPaint(
      size: Size(size, size),
      painter: _StyledDiscPainter(
        base: base,
        style: style,
        highlight: highlight,
      ),
    );
  }
}

class _StyledDiscPainter extends CustomPainter {
  final Color base;
  final int style;
  final bool highlight;
  _StyledDiscPainter(
      {required this.base, required this.style, required this.highlight});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final hsl = HSLColor.fromColor(base);

    // Cast shadow.
    canvas.drawOval(
      Rect.fromCenter(
          center: c + Offset(0, r * 0.22), width: r * 1.7, height: r * 0.5),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Shaded base body shared by all styles.
    canvas.drawCircle(
      c,
      r * 0.94,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [
            Color.lerp(Colors.white, base, 0.35)!,
            base,
            hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor(),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    final idx = style.clamp(0, DiscStyles.names.length - 1);
    switch (idx) {
      case 0: // Classic Acrylic
        _gloss(canvas, c, r, 0.30);
        break;
      case 1: // Polished Wood
        _woodGrain(canvas, c, r);
        _gloss(canvas, c, r, 0.12);
        break;
      case 2: // Glass Marble
        _swirl(canvas, c, r, Colors.white.withValues(alpha: 0.35), 3);
        _gloss(canvas, c, r, 0.30);
        break;
      case 3: // Marbled Stone
        _speckles(canvas, c, r, 7, Colors.white.withValues(alpha: 0.25));
        _speckles(canvas, c, r, 5, Colors.black.withValues(alpha: 0.22));
        _gloss(canvas, c, r, 0.10);
        break;
      case 4: // Brass Coin
        _ridgedEdge(canvas, c, r);
        _emboss(canvas, c, r, '★');
        break;
      case 5: // Candy Swirl
        _swirl(canvas, c, r, Colors.white.withValues(alpha: 0.55), 2);
        _gloss(canvas, c, r, 0.25);
        break;
      case 6: // Leather
        _stitchedEdge(canvas, c, r);
        _speckles(canvas, c, r, 9, Colors.black.withValues(alpha: 0.12));
        break;
      case 7: // Ivory Bone
        _gloss(canvas, c, r, 0.18);
        _crackle(canvas, c, r);
        break;
      case 8: // Poker Chip
        _chipSpots(canvas, c, r);
        _gloss(canvas, c, r, 0.15);
        break;
      case 9: // Hammered Steel
        _dents(canvas, c, r);
        _gloss(canvas, c, r, 0.28);
        break;
    }

    // Gloss edge + rim shared by all.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.9),
      -2.4,
      1.6,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = max(1.0, r * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      c,
      r * 0.94,
      Paint()
        ..color =
            hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0)).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, r * 0.05),
    );
    if (highlight) {
      canvas.drawCircle(
        c,
        r * 0.94,
        Paint()
          ..color = F4Colors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.0, r * 0.12),
      );
    }
  }

  void _gloss(Canvas canvas, Offset c, double r, double alpha) {
    canvas.drawCircle(
      c + Offset(-r * 0.28, -r * 0.32),
      r * 0.32,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _woodGrain(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * (0.25 + i * 0.16)),
        0.3,
        4.2,
        false,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.14)
          ..strokeWidth = max(1.0, r * 0.045)
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _swirl(Canvas canvas, Offset c, double r, Color color, int turns) {
    final path = Path();
    const steps = 60;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final ang = t * turns * 2 * pi;
      final rr = r * 0.75 * t;
      final p = c + Offset(cos(ang) * rr, sin(ang) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = max(1.5, r * 0.09)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _speckles(Canvas canvas, Offset c, double r, int seed, Color color) {
    final rand = Random(seed * 977 + 13);
    for (var i = 0; i < 26; i++) {
      final ang = rand.nextDouble() * 2 * pi;
      final rr = rand.nextDouble() * r * 0.7;
      canvas.drawCircle(
        c + Offset(cos(ang) * rr, sin(ang) * rr),
        r * (0.03 + rand.nextDouble() * 0.05),
        Paint()..color = color,
      );
    }
  }

  void _ridgedEdge(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 36; i++) {
      final ang = i / 36 * 2 * pi;
      canvas.drawLine(
        c + Offset(cos(ang) * r * 0.82, sin(ang) * r * 0.82),
        c + Offset(cos(ang) * r * 0.94, sin(ang) * r * 0.94),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..strokeWidth = max(1.0, r * 0.04),
      );
    }
  }

  void _emboss(Canvas canvas, Offset c, double r, String glyph) {
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: r * 0.8,
          color: Colors.black.withValues(alpha: 0.35),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, c - Offset(tp.width / 2, tp.height / 2) + const Offset(1, 2));
    final tp2 = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: r * 0.8,
          color: Colors.white.withValues(alpha: 0.35),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, c - Offset(tp2.width / 2, tp2.height / 2));
  }

  void _stitchedEdge(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 24; i++) {
      final ang = i / 24 * 2 * pi;
      final p = c + Offset(cos(ang) * r * 0.78, sin(ang) * r * 0.78);
      canvas.drawCircle(
          p, max(1.2, r * 0.035), Paint()..color = const Color(0xFFE8D8B8));
    }
  }

  void _crackle(Canvas canvas, Offset c, double r) {
    final rand = Random(99);
    for (var i = 0; i < 5; i++) {
      final a0 = rand.nextDouble() * 2 * pi;
      var p = c + Offset(cos(a0) * r * 0.2, sin(a0) * r * 0.2);
      final path = Path()..moveTo(p.dx, p.dy);
      for (var k = 0; k < 4; k++) {
        final a = a0 + (rand.nextDouble() - 0.5) * 1.2;
        p = p + Offset(cos(a) * r * 0.18, sin(a) * r * 0.18);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.10)
          ..strokeWidth = max(1.0, r * 0.02)
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _chipSpots(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 8; i++) {
      final ang = i / 8 * 2 * pi + 0.39;
      final p = c + Offset(cos(ang) * r * 0.80, sin(ang) * r * 0.80);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(ang);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r * 0.16, height: r * 0.30),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, r * 0.04),
    );
  }

  void _dents(Canvas canvas, Offset c, double r) {
    final rand = Random(7);
    for (var i = 0; i < 14; i++) {
      final ang = rand.nextDouble() * 2 * pi;
      final rr = rand.nextDouble() * r * 0.62;
      final p = c + Offset(cos(ang) * rr, sin(ang) * rr);
      canvas.drawCircle(
        p,
        r * (0.08 + rand.nextDouble() * 0.10),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StyledDiscPainter old) =>
      old.base != base || old.style != style || old.highlight != highlight;
}

/// Board toy frame in the chosen board accent (metal/wood).
class F4BoardFrame extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final int accentIndex;
  final Widget child;
  const F4BoardFrame({
    super.key,
    required this.theme,
    required this.accentIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cols = BoardAccents.colors(accentIndex, theme);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cols[0], cols[1], cols[2]],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.woodDeep,
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Per-side player tray: own disc, renameable name, active highlight and a
/// "thinking" narration line. Never auto-plays anything — pure display.
class PlayerTray extends StatelessWidget {
  final int side; // 0 red, 1 yellow
  final String name;
  final bool isBot;
  final bool active;
  final bool thinking;
  final F4ArcadeThemeDef theme;
  final int discStyle;
  final VoidCallback onRename;

  const PlayerTray({
    super.key,
    required this.side,
    required this.name,
    required this.isBot,
    required this.active,
    required this.thinking,
    required this.theme,
    required this.discStyle,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final discColor = side == 0 ? theme.redDisc : theme.amberDisc;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.woodDeep.withValues(alpha: active ? 0.95 : 0.55),
        border: Border.all(
          color: active ? theme.accentLight : theme.accent.withValues(alpha: 0.35),
          width: active ? 2.5 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: discColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          ThemedDisc(
            player: side,
            size: 44,
            theme: theme,
            style: discStyle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: F4Text.mono(16, color: theme.ivory),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBot)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: theme.accent.withValues(alpha: 0.35),
                          ),
                          child: Text(
                            'BOT',
                            style: F4Text.mono(11, color: theme.ivory),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    thinking
                        ? 'thinking…'
                        : (active ? 'your move' : 'waiting'),
                    key: ValueKey(thinking ? 't' : (active ? 'a' : 'w')),
                    style: F4Text.body.copyWith(
                      fontSize: 12,
                      color: thinking
                          ? theme.accentLight
                          : theme.ivory.withValues(alpha: 0.55),
                      fontStyle:
                          thinking ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRename,
            icon: Icon(Icons.edit, color: theme.ivory.withValues(alpha: 0.6), size: 20),
            tooltip: 'Rename player',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}
