import 'dart:math';
import 'package:flutter/material.dart';

const cream = Color(0xFFFAF8F2);
const ink = Color(0xFF1F201D);
const muted = Color(0xFF6B6D65);
const sage = Color(0xFF5F967F);
const tangerine = Color(0xFFF28C38);
const cSage = Color(0xFFDCEFD2);
const cSky = Color(0xFFCFEAF6);
const cPeach = Color(0xFFFDE3CF);
const cLav = Color(0xFFEAE2F8);
const cButter = Color(0xFFFDF2C5);
const cRose = Color(0xFFF4D9DE);
const cNight = Color(0xFF12303A);
const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink, height: 1.15);
const h2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink);
const bodyTx = TextStyle(fontSize: 14, color: muted, height: 1.35);

class PCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  const PCard({super.key, required this.color, required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(20), child: SizedBox(width: double.infinity, child: child)),
          ),
        ),
      );
}

class PillBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  const PillBtn(this.label, this.onTap, {super.key, this.bg = ink});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: bg, shape: const StadiumBorder()),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      );
}

InputDecoration fieldDec(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );

class Capy extends StatelessWidget {
  final double size;
  final bool sleepy;
  const Capy({super.key, this.size = 120, this.sleepy = false});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: CapyPainter(sleepy)));
}

class CapyPainter extends CustomPainter {
  final bool sleepy;
  CapyPainter(this.sleepy);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    Paint f(int v) => Paint()..color = Color(v);
    final line = Paint()
      ..color = const Color(0xFF3B2F26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .02
      ..strokeCap = StrokeCap.round;
    c.drawOval(Rect.fromLTWH(w * .14, h * .46, w * .72, h * .5), f(0xFFC9A27A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .3, h * .62, w * .4, h * .34), Radius.circular(w * .1)), f(0xFFFFFFFF));
    c.drawOval(Rect.fromLTWH(w * .2, h * .06, w * .13, h * .15), f(0xFFB88B62));
    c.drawOval(Rect.fromLTWH(w * .67, h * .06, w * .13, h * .15), f(0xFFB88B62));
    c.drawOval(Rect.fromLTWH(w * .2, h * .12, w * .6, h * .5), f(0xFFC9A27A));
    c.drawOval(Rect.fromLTWH(w * .34, h * .36, w * .32, h * .22), f(0xFFB88B62));
    c.drawCircle(Offset(w * .45, h * .42), w * .015, f(0xFF3B2F26));
    c.drawCircle(Offset(w * .55, h * .42), w * .015, f(0xFF3B2F26));
    if (sleepy) {
      c.drawArc(Rect.fromLTWH(w * .29, h * .29, w * .12, h * .06), 0, pi, false, line);
      c.drawArc(Rect.fromLTWH(w * .59, h * .29, w * .12, h * .06), 0, pi, false, line);
    } else {
      c.drawCircle(Offset(w * .35, h * .32), w * .026, f(0xFF3B2F26));
      c.drawCircle(Offset(w * .65, h * .32), w * .026, f(0xFF3B2F26));
    }
    c.drawCircle(Offset(w * .27, h * .44), w * .04, f(0x55F28C8C));
    c.drawCircle(Offset(w * .73, h * .44), w * .04, f(0x55F28C8C));
    final steth = Paint()
      ..color = const Color(0xFF6B6D65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .022;
    c.drawArc(Rect.fromLTWH(w * .36, h * .56, w * .28, h * .26), 0, pi, false, steth);
    c.drawCircle(Offset(w * .5, h * .84), w * .03, f(0xFF6B6D65));
  }

  @override
  bool shouldRepaint(CapyPainter old) => old.sleepy != sleepy;
}

class PondPainter extends CustomPainter {
  final int flowers;
  final double t;
  PondPainter(this.flowers, this.t);
  @override
  void paint(Canvas c, Size s) {
    final h = DateTime.now().hour;
    final day = h >= 6 && h < 17;
    final eve = h >= 17 && h < 20;
    final night = !day && !eve;
    final sky = day
        ? const [Color(0xFF8FD0E8), Color(0xFFDDF1F9)]
        : eve
            ? const [Color(0xFFF9D5DC), Color(0xFFFCEBB8)]
            : const [Color(0xFF12303A), Color(0xFF1E4A4F)];
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(r));
    c.drawCircle(Offset(s.width * .85, s.height * .16), 22, Paint()..color = night ? const Color(0xFFF3EFD0) : const Color(0xAAFFF3B0));
    final m = Path()
      ..moveTo(0, s.height * .55)
      ..quadraticBezierTo(s.width * .5, s.height * .45, s.width, s.height * .55)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(m, Paint()..color = night ? const Color(0xFF2E5B4F) : const Color(0xFFB9D98E));
    c.drawOval(Rect.fromCenter(center: Offset(s.width * .5, s.height * .74), width: s.width * .7, height: s.height * .3), Paint()..color = night ? const Color(0xFF28556A) : const Color(0xFF8CC7DD));
    c.drawRect(Rect.fromLTWH(s.width * .12 + 30, s.height * .08, 8, s.height * .44), Paint()..color = const Color(0xFF8A6B4F));
    final wp = Paint()
      ..color = night ? const Color(0xFF1C4036) : const Color(0xFF7FA95F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final x = s.width * .12 + i * 8.0;
      final sway = sin(t * 2 * pi + i) * 3;
      c.drawLine(Offset(x, s.height * .1), Offset(x + sway, s.height * .5), wp);
    }
    const cols = [Color(0xFFF28C38), Color(0xFFF4A6B8), Color(0xFFFFD166), Color(0xFFB8A9E8)];
    for (var i = 0; i < min(flowers, 24); i++) {
      final rng = Random(i + 7);
      final p = Offset(rng.nextDouble() * s.width, s.height * (.84 + rng.nextDouble() * .14));
      c.drawCircle(p, 6, Paint()..color = cols[i % 4]);
      c.drawCircle(p, 2, Paint()..color = Colors.white);
    }
    if (night) {
      for (var i = 0; i < 12; i++) {
        final rng = Random(i + 99);
        final p = Offset(rng.nextDouble() * s.width + sin(t * 2 * pi + i) * 6, s.height * (.3 + rng.nextDouble() * .4) + cos(t * 2 * pi + i) * 6);
        c.drawCircle(p, 2.5, Paint()..color = const Color(0xCCFFE680));
      }
    }
  }

  @override
  bool shouldRepaint(PondPainter old) => true;
}

class RingPainter extends CustomPainter {
  final double p;
  final Color fg, bg;
  RingPainter(this.p, {this.fg = tangerine, this.bg = const Color(0x33FFFFFF)});
  @override
  void paint(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, s.height / 2);
    final r = min(s.width, s.height) / 2 - 8;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    c.drawCircle(ctr, r, base..color = bg);
    c.drawArc(Rect.fromCircle(center: ctr, radius: r), -pi / 2, 2 * pi * p.clamp(0.0, 1.0), false, base..color = fg);
  }

  @override
  bool shouldRepaint(RingPainter old) => old.p != p;
}
