import 'dart:math';
import 'package:flutter/material.dart';

/// Tabletop Arcade Skeuomorph design tokens (Stitch project
/// "Four in a Row Game UI" — DESIGN.md is the visual source of truth).
class F4Colors {
  F4Colors._();
  static const red = Color(0xFFD63426); // Player 1 discs / primary
  static const amber = Color(0xFFF49F1C); // Player 2 discs / secondary
  static const cream = Color(0xFFF4EDE2); // button plungers, plaques
  static const chrome = Color(0xFF8C9095); // bezels, collars, knobs
  static const chromeLight = Color(0xFFC9CDD2);
  static const chromeDark = Color(0xFF565A5F);
  static const walnut = Color(0xFF1D100B); // cabinet surface
  static const chassis = Color(0xFF1E1613); // dark iron plates
  static const slot = Color(0xFF150C0A); // recessed channels
  static const deboss = Color(0xFF3C2D26); // text on cream
  static const warmText = Color(0xFFF8DDD4); // text on dark
  static const gold = Color(0xFFE08F00); // trophy
  static const jewelOff = Color(0xFF5A3B0A);
  static const mechShadow = Color(0xFF120A07); // button drop shadow

  static Color discBase(int player) => player == 0 ? red : amber;
}

/// Typography: Epilogue-900-style bevelled headlines, Work-Sans-style body,
/// Space-Mono-style debossed readouts — rendered with system fonts.
class F4Text {
  F4Text._();

  static TextStyle headline(double size, {Color color = F4Colors.cream}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: color,
        shadows: const [
          Shadow(offset: Offset(0, 2), color: Color(0xAA000000), blurRadius: 0),
          Shadow(offset: Offset(0, -1), color: Color(0x55FFFFFF), blurRadius: 0),
        ],
      );

  static TextStyle plaqueTitle(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.5,
        color: F4Colors.deboss,
        shadows: const [
          Shadow(offset: Offset(0, 1), color: Color(0x99FFFFFF), blurRadius: 0),
        ],
      );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: F4Colors.warmText,
  );

  static TextStyle mono(double size, {Color color = F4Colors.warmText}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color,
        shadows: const [
          Shadow(offset: Offset(0, 1), color: Color(0x88000000), blurRadius: 0),
        ],
      );

  static TextStyle monoDeboss(double size) => TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: F4Colors.deboss,
      );
}

/// Walnut cabinet backdrop: dark wood, soft grain streaks, tungsten vignette.
class WalnutBackground extends StatelessWidget {
  final Widget child;
  const WalnutBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WalnutPainter(),
      child: child,
    );
  }
}

class _WalnutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = F4Colors.walnut);
    final rand = Random(42);
    // subtle horizontal wood grain
    for (var i = 0; i < 26; i++) {
      final y = rand.nextDouble() * size.height;
      final light = rand.nextBool();
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (rand.nextDouble() - 0.5) * 30),
        Paint()
          ..color = light
              ? const Color(0x0AF8DDD4)
              : const Color(0x14000000)
          ..strokeWidth = 1 + rand.nextDouble() * 3,
      );
    }
    // tungsten vignette: warm center, dark falloff at edges
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chunky cream arcade push-button in a brushed-chrome collar.
/// Resting: 4px mechanical shadow. Pressed: drops 4px, shadow collapses.
class ArcadeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final bool round;
  final double width;
  final IconData? icon;

  const ArcadeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 64,
    this.fontSize = 17,
    this.round = false,
    this.width = double.infinity,
    this.icon,
  });

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _down = false;

  void _setDown(bool v) {
    if (widget.onPressed == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.round ? widget.height / 2 : 16.0;
    return GestureDetector(
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) {
        _setDown(false);
        widget.onPressed?.call();
      },
      onTapCancel: () => _setDown(false),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // mechanical drop shadow
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 0,
              right: 0,
              top: _down ? 1 : 5,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: F4Colors.mechShadow,
                  borderRadius: BorderRadius.circular(radius + 3),
                ),
              ),
            ),
            // chrome collar
            Positioned.fill(
              bottom: _down ? 1 : 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius + 3),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      F4Colors.chromeLight,
                      F4Colors.chrome,
                      F4Colors.chromeDark,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            // dark inner ring
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 3,
              right: 3,
              top: _down ? 4 : 3,
              bottom: _down ? 4 : 8,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0806),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
            // cream plunger
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 6,
              right: 6,
              top: _down ? 9 : 6,
              bottom: _down ? 7 : 11,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius - 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFBF3), F4Colors.cream, Color(0xFFE3D5BF)],
                    stops: [0.0, 0.6, 1.0],
                  ),
                  boxShadow: _down
                      ? [
                          const BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : const [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: F4Colors.deboss, size: widget.fontSize + 4),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: F4Text.plaqueTitle(widget.fontSize),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cream title plaque with chrome trim — for marquee titles and badges.
class ChromePlaque extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? accent;
  const ChromePlaque({super.key, required this.text, this.fontSize = 30, this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [F4Colors.chromeLight, F4Colors.chrome, F4Colors.chromeDark],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF3), F4Colors.cream, Color(0xFFE8DAC4)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2), spreadRadius: -1),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: F4Text.plaqueTitle(fontSize).copyWith(
            color: accent ?? F4Colors.deboss,
          ),
        ),
      ),
    );
  }
}

/// Dark iron status plaque with chrome strip border + corner brackets.
class IronPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const IronPanel({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: F4Colors.chassis,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: F4Colors.chrome.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 14, offset: const Offset(0, 6)),
          const BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Physical two-position bat-handle switch with an acrylic jewel pip.
class BatToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const BatToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: 84,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // iron base plate
            Container(
              width: 84,
              height: 52,
              decoration: BoxDecoration(
                color: F4Colors.slot,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: F4Colors.chrome, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0xAA000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
            // recessed slot
            Container(
              width: 40,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0B0605),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF000000), blurRadius: 5, offset: Offset(0, 2)),
                ],
              ),
            ),
            // bat handle
            AnimatedRotation(
              turns: value ? -0.09 : 0.09,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutBack,
              child: Container(
                width: 14,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [F4Colors.chromeDark, F4Colors.chromeLight, F4Colors.chromeDark],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 18,
                  height: 14,
                  decoration: BoxDecoration(
                    color: F4Colors.cream,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1))],
                  ),
                ),
              ),
            ),
            // jewel pip
            Positioned(
              right: 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? F4Colors.amber : F4Colors.jewelOff,
                  boxShadow: value
                      ? [
                          BoxShadow(color: F4Colors.amber.withValues(alpha: 0.55), blurRadius: 8, spreadRadius: 2),
                        ]
                      : const [],
                  border: Border.all(color: F4Colors.chromeDark, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chrome-knob slider on a recessed slot track.
class ChromeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const ChromeSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        const knobR = 15.0;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            final v = ((d.localPosition.dx - knobR) / (w - knobR * 2)).clamp(0.0, 1.0);
            onChanged(v);
          },
          onTapDown: (d) {
            final v = ((d.localPosition.dx - knobR) / (w - knobR * 2)).clamp(0.0, 1.0);
            onChanged(v);
          },
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // recessed track
                Container(
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: knobR),
                  decoration: BoxDecoration(
                    color: F4Colors.slot,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF000000), blurRadius: 5, offset: Offset(0, 2)),
                    ],
                    border: Border.all(color: F4Colors.chromeDark, width: 1),
                  ),
                ),
                // brass fill
                Positioned(
                  left: knobR,
                  child: Container(
                    height: 6,
                    width: (w - knobR * 2) * value,
                    decoration: BoxDecoration(
                      color: F4Colors.gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // chrome knob
                Positioned(
                  left: knobR + (w - knobR * 2) * value - knobR,
                  child: Container(
                    width: knobR * 2,
                    height: knobR * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.35, -0.4),
                        colors: [F4Colors.chromeLight, F4Colors.chrome, F4Colors.chromeDark],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      border: Border.all(color: const Color(0xFF3A3D41), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Translucent acrylic game disc with dual internal highlights,
/// gloss edge and a soft cast shadow.
class AcrylicDisc extends StatelessWidget {
  final int player; // 0 red, 1 yellow
  final double size;
  final bool highlight;
  const AcrylicDisc({super.key, required this.player, required this.size, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final base = F4Colors.discBase(player);
    return CustomPaint(
      size: Size(size, size),
      painter: _DiscPainter(base: base, highlight: highlight),
    );
  }
}

class _DiscPainter extends CustomPainter {
  final Color base;
  final bool highlight;
  _DiscPainter({required this.base, required this.highlight});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final hsl = HSLColor.fromColor(base);

    // cast shadow
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r * 0.22), width: r * 1.7, height: r * 0.5),
      Paint()..color = const Color(0x66000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // acrylic body
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
    // secondary internal highlight
    canvas.drawCircle(
      c + Offset(-r * 0.28, -r * 0.32),
      r * 0.32,
      Paint()..color = Colors.white.withValues(alpha: 0.30)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // gloss edge
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
    // rim
    canvas.drawCircle(
      c,
      r * 0.94,
      Paint()
        ..color = hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0)).toColor()
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

  @override
  bool shouldRepaint(covariant _DiscPainter old) =>
      old.base != base || old.highlight != highlight;
}

/// Empty recessed slot on the board.
class BoardSlot extends StatelessWidget {
  final double size;
  const BoardSlot({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _SlotPainter());
  }
}

class _SlotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    // deep inset
    canvas.drawCircle(
      c,
      r * 0.94,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.3, 0.4),
          radius: 1.0,
          colors: [Color(0xFF050302), Color(0xFF150C0A), Color(0xFF241512)],
          stops: [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // inner top shadow lip
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.9),
      0.4,
      2.3,
      false,
      Paint()
        ..color = const Color(0xAA000000)
        ..strokeWidth = max(1.0, r * 0.08)
        ..style = PaintingStyle.stroke,
    );
    // bottom rim catchlight
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.9),
      3.6,
      1.8,
      false,
      Paint()
        ..color = const Color(0x33C9CDD2)
        ..strokeWidth = max(1.0, r * 0.05)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gold trophy cup on a pedestal (game-over screen).
class Trophy extends StatelessWidget {
  final double size;
  const Trophy({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _TrophyPainter());
  }
}

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gold = F4Colors.gold;
    final dark = const Color(0xFF8A5600);
    final light = const Color(0xFFFFD98A);
    Paint paintOf(Color col) => Paint()..color = col;

    // pedestal
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.3, h * 0.78, w * 0.4, h * 0.16), const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(colors: [dark, gold, dark]).createShader(Rect.fromLTWH(0, h * 0.78, w, h * 0.16)),
    );
    // stem
    canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.62, w * 0.12, h * 0.16),
        Paint()..shader = LinearGradient(colors: [dark, light, dark]).createShader(Rect.fromLTWH(w * 0.44, h * 0.62, w * 0.12, h * 0.16)));
    // cup body
    final body = Path()
      ..moveTo(w * 0.28, h * 0.08)
      ..quadraticBezierTo(w * 0.28, h * 0.5, w * 0.44, h * 0.62)
      ..lineTo(w * 0.56, h * 0.62)
      ..quadraticBezierTo(w * 0.72, h * 0.5, w * 0.72, h * 0.08)
      ..close();
    canvas.drawPath(body, Paint()..shader = LinearGradient(colors: [light, gold, dark, gold]).createShader(Rect.fromLTWH(w * 0.28, 0, w * 0.44, h * 0.62)));
    // rim
    canvas.drawOval(Rect.fromLTWH(w * 0.26, h * 0.04, w * 0.48, h * 0.08), paintOf(light));
    canvas.drawOval(Rect.fromLTWH(w * 0.3, h * 0.05, w * 0.4, h * 0.06), paintOf(const Color(0xFF5A3600)));
    // handles
    for (final s in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromLTWH(s < 0 ? w * 0.1 : w * 0.62, h * 0.14, w * 0.28, h * 0.3),
        s < 0 ? 1.2 : 0.7,
        2.6,
        false,
        Paint()..color = gold..strokeWidth = w * 0.05..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
      );
    }
    // sparkle
    canvas.drawCircle(Offset(w * 0.4, h * 0.24), w * 0.03, paintOf(Colors.white.withValues(alpha: 0.8)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paper confetti burst (celebration, non-neon).
class Confetti extends StatefulWidget {
  final bool active;
  const Confetti({super.key, required this.active});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  final _rand = Random(1234);
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    const cols = [Color(0xFFD63426), Color(0xFFF49F1C), Color(0xFFF4EDE2), Color(0xFFE08F00), Color(0xFF8C9095)];
    _pieces = List.generate(
      90,
      (_) => _Piece(
        x: _rand.nextDouble(),
        delay: _rand.nextDouble() * 0.5,
        speed: 0.5 + _rand.nextDouble() * 0.8,
        size: 5 + _rand.nextDouble() * 7,
        rot: _rand.nextDouble() * 6.28,
        spin: (_rand.nextDouble() - 0.5) * 12,
        drift: (_rand.nextDouble() - 0.5) * 0.3,
        color: cols[_rand.nextInt(cols.length)],
      ),
    );
    if (widget.active) _ctl.forward();
  }

  @override
  void didUpdateWidget(Confetti old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _ctl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) => CustomPaint(
        painter: _ConfettiPainter(pieces: _pieces, t: _ctl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Piece {
  final double x, delay, speed, size, rot, spin, drift;
  final Color color;
  _Piece({required this.x, required this.delay, required this.speed, required this.size, required this.rot, required this.spin, required this.drift, required this.color});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter({required this.pieces, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final y = lt * p.speed * size.height * 1.1 - size.height * 0.05;
      final x = (p.x + p.drift * lt) * size.width;
      final fade = (1 - lt).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + p.spin * lt);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.62),
        Paint()..color = p.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
