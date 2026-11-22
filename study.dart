import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'art.dart';
import 'data.dart';

class StudyTab extends StatefulWidget {
  const StudyTab({super.key});
  @override
  State<StudyTab> createState() => _StudyTabState();
}

class _StudyTabState extends State<StudyTab> {
  late String subject = Prefs.subjects.first;
  String mode = modes.first;
  int mins = 25;
  final goal = TextEditingController();

  Widget block(Color col, String title, List<Widget> chips) => PCard(
        color: col,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: h2),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: chips),
        ]),
      );

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Study session', style: h1),
        const SizedBox(height: 16),
        block(cPeach, 'Subject', [
          for (final s in Prefs.subjects) ChoiceChip(label: Text(s), selected: subject == s, onSelected: (_) => setState(() => subject = s)),
        ]),
        block(cSky, 'What are you doing?', [
          for (final m in modes) ChoiceChip(label: Text(m), selected: mode == m, onSelected: (_) => setState(() => mode = m)),
        ]),
        block(cSage, 'Duration', [
          for (final d in durations) ChoiceChip(label: Text(d == 180 ? '180m Paper Sim' : '${d}m'), selected: mins == d, onSelected: (_) => setState(() => mins = d)),
        ]),
        TextField(controller: goal, decoration: fieldDec('One-line goal (e.g. Brachial plexus)')),
        const SizedBox(height: 16),
        PillBtn('Start', () {
          FocusScope.of(context).unfocus();
          Navigator.push(context, MaterialPageRoute(builder: (_) => TimerPage(subject: subject, mode: mode, mins: mins, goal: goal.text.trim())));
        }),
      ]);
}

class TimerPage extends StatefulWidget {
  final String subject, mode, goal;
  final int mins;
  const TimerPage({super.key, required this.subject, required this.mode, required this.mins, required this.goal});
  @override
  State<TimerPage> createState() => _TimerState();
}

class _TimerState extends State<TimerPage> with SingleTickerProviderStateMixin {
  static const ch = MethodChannel('focusguard/blocker');
  final start = DateTime.now();
  Timer? tm;
  int el = 0;
  bool dim = false, done = false;
  late final AnimationController ac = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    keep(true);
    tm = Timer.periodic(const Duration(seconds: 1), (_) {
      final e = DateTime.now().difference(start).inSeconds;
      if (e >= widget.mins * 60) {
        finish();
      } else {
        setState(() => el = e);
      }
    });
  }

  Future<void> keep(bool on) async {
    try {
      await ch.invokeMethod('keepOn', on);
    } catch (_) {}
  }

  void finish() {
    if (done) return;
    done = true;
    tm?.cancel();
    HapticFeedback.heavyImpact();
    final secs = min(DateTime.now().difference(start).inSeconds, widget.mins * 60);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SummaryPage(subject: widget.subject, mode: widget.mode, goal: widget.goal, secs: secs, startMs: start.millisecondsSinceEpoch)));
  }

  Future<void> quit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('End session?'),
        content: const Text('Your time so far will be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Keep going')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('End')),
        ],
      ),
    );
    if (ok == true && mounted) finish();
  }

  @override
  void dispose() {
    tm?.cancel();
    ac.dispose();
    keep(false);
    super.dispose();
  }

  String fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = widget.mins * 60;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) quit();
      },
      child: Scaffold(
        backgroundColor: cNight,
        body: Stack(children: [
          SafeArea(
            child: Column(children: [
              const SizedBox(height: 20),
              Text('${widget.subject} · ${widget.mode}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              if (widget.goal.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(widget.goal, style: const TextStyle(color: Colors.white70))),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(alignment: Alignment.center, children: [
                      CustomPaint(size: const Size(280, 280), painter: RingPainter(el / total)),
                      AnimatedBuilder(
                        animation: ac,
                        builder: (_, __) => Transform.translate(offset: Offset(0, ac.value * 8 - 4), child: const Capy(size: 150)),
                      ),
                    ]),
                  ),
                ),
              ),
              Text(fmt(total - el), style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => dim = true), child: const Text('Stealth dim', style: TextStyle(color: Colors.white)))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: tangerine), onPressed: quit, child: const Text('Finish'))),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
          if (dim) Positioned.fill(child: GestureDetector(onTap: () => setState(() => dim = false), child: Container(color: Colors.black))),
        ]),
      ),
    );
  }
}

class SummaryPage extends StatefulWidget {
  final String subject, mode, goal;
  final int secs, startMs;
  const SummaryPage({super.key, required this.subject, required this.mode, required this.goal, required this.secs, required this.startMs});
  @override
  State<SummaryPage> createState() => _SumState();
}

class _SumState extends State<SummaryPage> {
  late final log = TextEditingController(text: widget.goal);
  bool hy = false;
  int get mins => widget.secs ~/ 60;
  bool get nightOwl {
    final h = DateTime.now().hour;
    return h >= 1 && h < 5;
  }

  int get xp => nightOwl ? mins ~/ 2 : mins;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const Center(child: Capy(size: 130)),
            const SizedBox(height: 8),
            Center(child: Text(mins >= 1 ? '$mins min · +$xp XP' : 'Too short to count', style: h1)),
            if (nightOwl) const Padding(padding: EdgeInsets.only(top: 8), child: Text("It's late, so XP is halved. Sleep is revision too.", style: bodyTx, textAlign: TextAlign.center)),
            const SizedBox(height: 20),
            const Text('What did you cover? (becomes a revision card)', style: h2),
            const SizedBox(height: 8),
            TextField(controller: log, decoration: fieldDec('One line')),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('High-Yield ★'), value: hy, onChanged: (v) => setState(() => hy = v)),
            const SizedBox(height: 12),
            PillBtn(mins >= 1 ? 'Save to pond' : 'Discard', () async {
              if (mins >= 1) {
                await DB.addSession(widget.startMs, widget.secs, widget.subject, widget.mode, log.text.trim(), xp, hy);
                if (log.text.trim().isNotEmpty) {
                  await DB.addPearl(widget.subject, 'Recall: ${log.text.trim()}', 'Say everything you remember first, then check your notes.', hy);
                }
              }
              if (!mounted) return;
              Navigator.popUntil(context, (r) => r.isFirst);
            }),
          ]),
        ),
      );
}
