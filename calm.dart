import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'art.dart';
import 'data.dart';

class CalmTab extends StatelessWidget {
  const CalmTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Calm', style: h1),
        const SizedBox(height: 12),
        PCard(
          color: cSky,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreathPage())),
          child: const Row(children: [Icon(Icons.air), SizedBox(width: 12), Expanded(child: Text('Box breathing · 4-4-4-4\nGood before a viva or exam', style: h2))]),
        ),
        PCard(
          color: cSage,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WinsPage())),
          child: const Row(children: [Icon(Icons.emoji_events_outlined), SizedBox(width: 12), Expanded(child: Text('Small Wins Jar\nLog one tiny win today', style: h2))]),
        ),
        PCard(
          color: cRose,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('How are you feeling?', style: h2),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (var i = 0; i < 5; i++)
                GestureDetector(
                  onTap: () async {
                    await DB.addMood(i + 1);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for checking in. Be gentle with yourself today.')));
                  },
                  child: Text(['😞', '😕', '😐', '🙂', '😄'][i], style: const TextStyle(fontSize: 34)),
                ),
            ]),
          ]),
        ),
        const PCard(
          color: cButter,
          child: Text('This app is a study and habit companion, not therapy. If you are struggling, please talk to someone you trust or a professional. In India, Tele-MANAS offers free support on 14416 (please verify the number).', style: bodyTx),
        ),
      ]);
}

class BreathPage extends StatefulWidget {
  const BreathPage({super.key});
  @override
  State<BreathPage> createState() => _BreathState();
}

class _BreathState extends State<BreathPage> with SingleTickerProviderStateMixin {
  late final AnimationController ac = AnimationController(vsync: this, duration: const Duration(seconds: 64))..forward();
  int last = -1;
  @override
  void initState() {
    super.initState();
    ac.addListener(() {
      final ph = ((ac.value * 64) % 16) ~/ 4;
      if (ph != last) {
        last = ph;
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cSky,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: ac,
            builder: (_, __) {
              final t = (ac.value * 64) % 16;
              final ph = ac.isCompleted ? 1 : (t ~/ 4);
              final fr = (t % 4) / 4;
              final sc = ph == 0 ? .6 + .4 * fr : ph == 1 ? 1.0 : ph == 2 ? 1 - .4 * fr : .6;
              final cycle = ((ac.value * 4).floor() + 1).clamp(1, 4);
              return Column(children: [
                Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
                const Text('Box breathing', style: h1),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 280 * sc,
                      height: 280 * sc,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x88FFFFFF)),
                      child: Center(child: Capy(size: 130 * sc, sleepy: ph == 1 || ph == 3)),
                    ),
                  ),
                ),
                Text(ac.isCompleted ? 'Well done' : ['Inhale', 'Hold', 'Exhale', 'Hold'][ph], style: h1),
                Text(ac.isCompleted ? 'Four calm cycles complete.' : 'Cycle $cycle / 4', style: bodyTx),
                const SizedBox(height: 32),
              ]);
            },
          ),
        ),
      );
}

class WinsPage extends StatefulWidget {
  const WinsPage({super.key});
  @override
  State<WinsPage> createState() => _WinsState();
}

class _WinsState extends State<WinsPage> {
  List<Map<String, Object?>> wins = [];
  final t = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final w = await DB.wins();
    if (!mounted) return;
    setState(() => wins = w);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Small Wins Jar'), backgroundColor: cream),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(controller: t, decoration: fieldDec('Today I managed to...')),
          const SizedBox(height: 12),
          PillBtn('Drop it in the jar', () async {
            if (t.text.trim().isEmpty) return;
            await DB.addWin(t.text.trim());
            t.clear();
            load();
          }),
          const SizedBox(height: 16),
          Text('${wins.length} wins so far', style: h2),
          for (final w in wins) ListTile(leading: const Icon(Icons.favorite, color: tangerine), title: Text('${w['text']}')),
        ]),
      );
}
