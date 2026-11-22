import 'package:flutter/material.dart';
import 'art.dart';
import 'data.dart';

class ReviseTab extends StatefulWidget {
  const ReviseTab({super.key});
  @override
  State<ReviseTab> createState() => _ReviseState();
}

class _ReviseState extends State<ReviseTab> {
  List<Map<String, Object?>> cards = [];
  bool show = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final c = await DB.duePearls();
    if (!mounted) return;
    setState(() {
      cards = c;
      show = false;
    });
  }

  Future<void> rate(int r) async {
    await DB.rate(cards.first, r);
    await load();
  }

  Future<void> add() async {
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => const AddPearl());
    if (ok == true) load();
  }

  @override
  Widget build(BuildContext context) {
    final cur = cards.isEmpty ? null : cards.first;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [const Text('Revise', style: h1), const Spacer(), Chip(label: Text('${cards.length} due'))]),
      const SizedBox(height: 12),
      if (cur == null)
        const PCard(
          color: cButter,
          child: Column(children: [
            Capy(size: 110),
            SizedBox(height: 8),
            Text('All revisions cleared', style: h2),
            Text('Your future self thanks you.', style: bodyTx),
          ]),
        )
      else ...[
        PCard(
          color: cLav,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${cur['subject']}${cur['hy'] == 1 ? '  ★' : ''}', style: bodyTx),
            const SizedBox(height: 10),
            Text('${cur['front']}', style: h2),
            if (show) ...[const Divider(height: 28), Text('${cur['back']}'.isEmpty ? '—' : '${cur['back']}', style: const TextStyle(fontSize: 16, color: ink))],
          ]),
        ),
        if (!show)
          PillBtn('Show answer', () => setState(() => show = true))
        else
          Row(children: [
            for (final e in const {1: 'Again', 2: 'Hard', 3: 'Good', 4: 'Easy'}.entries)
              Expanded(child: Padding(padding: const EdgeInsets.all(3), child: OutlinedButton(onPressed: () => rate(e.key), child: Text(e.value)))),
          ]),
      ],
      const SizedBox(height: 20),
      PillBtn('+ Add Pearl', add, bg: tangerine),
    ]);
  }
}

class AddPearl extends StatefulWidget {
  const AddPearl({super.key});
  @override
  State<AddPearl> createState() => _AddPearlState();
}

class _AddPearlState extends State<AddPearl> {
  late String subject = Prefs.subjects.first;
  final f = TextEditingController(), b = TextEditingController();
  bool hy = false;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButton<String>(
              value: subject,
              isExpanded: true,
              items: [for (final s in Prefs.subjects) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => setState(() => subject = v ?? subject),
            ),
            TextField(controller: f, decoration: const InputDecoration(labelText: 'Pearl / question')),
            TextField(controller: b, maxLines: 3, decoration: const InputDecoration(labelText: 'Answer / note')),
            SwitchListTile(title: const Text('High-Yield ★'), value: hy, onChanged: (v) => setState(() => hy = v)),
            PillBtn('Save', () async {
              if (f.text.trim().isEmpty) return;
              await DB.addPearl(subject, f.text.trim(), b.text.trim(), hy);
              if (!mounted) return;
              Navigator.pop(context, true);
            }),
          ]),
        ),
      );
}
