import 'dart:math';
import 'package:flutter/material.dart';
import 'art.dart';
import 'data.dart';

class Home extends StatefulWidget {
  final void Function(int) go;
  const Home({super.key, required this.go});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late final AnimationController ac = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  int todaySecs = 0, streak = 0, due = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final m = await DB.secsByDay(400);
    final d = await DB.dueCount();
    if (!mounted) return;
    setState(() {
      todaySecs = m[DB.midnight(DateTime.now())] ?? 0;
      streak = DB.streakOf(m);
      due = d;
    });
  }

  @override
  void dispose() {
    ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = Prefs.exam;
    final days = ex?.difference(DateTime.now()).inDays;
    final goalH = dayTypes[Prefs.dayType] ?? 2;
    final prog = (todaySecs / (goalH * 3600)).clamp(0.0, 1.0);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        const Text('Pulse Pond', style: h1),
        const Spacer(),
        if (days != null) Chip(label: Text('${days < 0 ? 0 : days}d to exam')),
        const SizedBox(width: 8),
        const Icon(Icons.water_drop, color: sage),
        Text('$streak', style: h2),
      ]),
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 280,
          child: AnimatedBuilder(
            animation: ac,
            builder: (_, __) => Stack(children: [
              Positioned.fill(child: CustomPaint(painter: PondPainter(todaySecs ~/ 1200, ac.value))),
              Align(
                alignment: const Alignment(0, .4),
                child: Transform.translate(offset: Offset(0, sin(ac.value * 2 * pi) * 4), child: const Capy(size: 110)),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: [
        for (final k in dayTypes.keys)
          ChoiceChip(
            label: Text(k),
            selected: Prefs.dayType == k,
            onSelected: (_) async {
              await Prefs.setDay(k);
              setState(() {});
            },
          ),
      ]),
      const SizedBox(height: 10),
      PCard(
        color: cSage,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Today's progress", style: h2),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: prog, minHeight: 10, borderRadius: BorderRadius.circular(8), color: sage, backgroundColor: Colors.white),
          const SizedBox(height: 8),
          Text('${(todaySecs / 60).round()} / ${goalH * 60} min', style: bodyTx),
          Text(todaySecs == 0 ? 'Ready when you are. A flower blooms every 20 minutes.' : 'The pond is blooming.', style: bodyTx),
        ]),
      ),
      PCard(
        color: cLav,
        onTap: () => widget.go(2),
        child: Row(children: [
          const Icon(Icons.style, color: ink),
          const SizedBox(width: 12),
          Expanded(child: Text(due == 0 ? 'All revisions cleared' : '$due revision cards due', style: h2)),
          const Icon(Icons.chevron_right),
        ]),
      ),
      PillBtn('Start studying', () => widget.go(1)),
    ]);
  }
}
