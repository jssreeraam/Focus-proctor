import 'package:flutter/material.dart';
import 'art.dart';
import 'data.dart';

class TrackTab extends StatefulWidget {
  const TrackTab({super.key});
  @override
  State<TrackTab> createState() => _TrackState();
}

class _TrackState extends State<TrackTab> {
  Map<int, int> m = {};
  List<Map<String, Object?>> subj = [];
  Map<String, List<int>> att = {};
  int xp = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final a = await DB.secsByDay(400);
    final s = await DB.subjectSecs(30);
    final t = await DB.allAtt();
    final x = await DB.totalXp();
    if (!mounted) return;
    setState(() {
      m = a;
      subj = s;
      att = t;
      xp = x;
    });
  }

  String bunk(int held, int a) {
    if (held == 0) return 'No classes logged';
    final v = 4 * a - 3 * held; // 75% threshold; verify your university's rule
    if (v >= 0) return 'Safe to skip ${v ~/ 3} more';
    return 'Attend next ${-v} classes to reach 75%';
  }

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    final goal = (dayTypes[Prefs.dayType] ?? 2) * 3600;
    final total = m.values.fold<int>(0, (a, b) => a + b);
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Track', style: h1),
      const SizedBox(height: 12),
      PCard(
        color: cButter,
        child: Row(children: [
          const Icon(Icons.water_drop, color: tangerine, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${DB.streakOf(m)} day streak', style: h2),
            Text('${rankOf(xp)} · $xp XP · ${(total / 3600).toStringAsFixed(1)} h total', style: bodyTx),
          ])),
        ]),
      ),
      PCard(
        color: cSage,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Last 7 days', style: h2),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 6; i >= 0; i--)
              Builder(builder: (_) {
                final d = DateTime(n.year, n.month, n.day - i);
                final s = m[DB.midnight(d)] ?? 0;
                return Column(children: [
                  Container(width: 22, height: 6 + 80 * (s / goal).clamp(0.0, 1.0), decoration: BoxDecoration(color: s >= goal ? sage : Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 4),
                  Text('MTWTFSS'[d.weekday - 1], style: bodyTx),
                ]);
              }),
          ]),
        ]),
      ),
      PCard(
        color: cSky,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('30-day consistency', style: h2),
          const SizedBox(height: 10),
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (var i = 29; i >= 0; i--)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color.fromARGB(() {
                    final s = m[DB.midnight(DateTime(n.year, n.month, n.day - i))] ?? 0;
                    return s == 0 ? 25 : (70 + 185 * (s / 10800).clamp(0.0, 1.0)).round();
                  }(), 95, 150, 127),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ]),
        ]),
      ),
      PCard(
        color: cPeach,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Subjects, last 30 days', style: h2),
          const SizedBox(height: 8),
          if (subj.isEmpty) const Text('Nothing yet.', style: bodyTx),
          for (final r in subj) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text('${r['subject']}')), Text('${((r['s'] as int) / 3600).toStringAsFixed(1)} h', style: bodyTx)])),
        ]),
      ),
      PCard(
        color: cLav,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Attendance guard (theory, 75%)', style: h2),
          const Text('Tap ✓ or ✗ after each class. Check your university\'s actual rule.', style: bodyTx),
          const SizedBox(height: 8),
          for (final s in Prefs.subjects)
            Builder(builder: (_) {
              final v = att[s] ?? [0, 0];
              final pct = v[0] == 0 ? 0 : (100 * v[1] / v[0]).round();
              return Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$s  ${v[1]}/${v[0]} ($pct%)', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(bunk(v[0], v[1]), style: bodyTx),
                ])),
                IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: () async { await DB.bumpAtt(s, true); load(); }),
                IconButton(icon: const Icon(Icons.cancel_outlined), onPressed: () async { await DB.bumpAtt(s, false); load(); }),
              ]);
            }),
        ]),
      ),
    ]);
  }
}
