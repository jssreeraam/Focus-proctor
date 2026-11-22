import 'package:flutter/material.dart';
import 'art.dart';
import 'data.dart';
import 'home.dart';
import 'study.dart';
import 'revise.dart';
import 'track.dart';
import 'calm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  await DB.init();
  runApp(const PondApp());
}

class PondApp extends StatelessWidget {
  const PondApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pulse Pond',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: sage, scaffoldBackgroundColor: cream),
        home: Prefs.phase.isEmpty ? const Onboarding() : const Shell(),
      );
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnbState();
}

class _OnbState extends State<Onboarding> {
  String phase = phases.keys.first;
  DateTime? exam;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Center(child: Capy(size: 150)),
            const SizedBox(height: 12),
            const Text("Hi, I'm Capy.", style: h1),
            const SizedBox(height: 6),
            const Text("Let's set up your pond. Which year are you in?", style: bodyTx),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final k in phases.keys) ChoiceChip(label: Text(k), selected: phase == k, onSelected: (_) => setState(() => phase = k)),
            ]),
            const SizedBox(height: 24),
            const Text('University exam date (optional, change anytime)', style: h2),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final n = DateTime.now();
                final d = await showDatePicker(context: context, initialDate: n.add(const Duration(days: 90)), firstDate: n, lastDate: n.add(const Duration(days: 1100)));
                if (d != null) setState(() => exam = d);
              },
              child: Text(exam == null ? 'Pick a date' : '${exam!.day}/${exam!.month}/${exam!.year}'),
            ),
            const SizedBox(height: 28),
            PillBtn('Start', () async {
              await Prefs.save(phase, exam);
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Shell()));
            }),
          ]),
        ),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  void go(int n) => setState(() => i = n);
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[Home(go: go), const StudyTab(), const ReviseTab(), const TrackTab(), const CalmTab()];
    return Scaffold(
      body: SafeArea(child: pages[i]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop), label: 'Pond'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: 'Revise'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Track'),
          NavigationDestination(icon: Icon(Icons.spa_outlined), selectedIcon: Icon(Icons.spa), label: 'Calm'),
        ],
      ),
    );
  }
}
