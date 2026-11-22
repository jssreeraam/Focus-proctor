import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

const phases = <String, List<String>>{
  '1st Prof': ['Anatomy', 'Physiology', 'Biochemistry'],
  '2nd Prof': ['Pathology', 'Pharmacology', 'Microbiology', 'Community Medicine', 'Forensic Medicine'],
  '3rd Prof Part 1': ['Community Medicine', 'Forensic Medicine', 'ENT', 'Ophthalmology'],
  '3rd Prof Part 2': ['Medicine', 'Surgery', 'OBG', 'Pediatrics', 'Orthopedics', 'Dermatology', 'Psychiatry', 'Anesthesia', 'Radiology'],
};
const modes = ['Theory Reading', 'MCQ', 'Practical / Spotters', 'Dissection Prep', 'Viva Prep', 'Clinical Cases', 'Revision', 'Mock Paper'];
const durations = [15, 25, 50, 90, 180];
const dayTypes = <String, int>{'College Day': 2, 'Free Day': 6, 'Exam Leave': 9};
const ranks = ['Fresher', 'Hall Regular', 'Ward Rookie', 'Clinical Clerk', 'Final-Year Finisher', 'Distinction Contender'];
const rankXp = [0, 300, 1500, 4000, 9000, 18000];

String rankOf(int xp) {
  var r = 0;
  for (var i = 0; i < rankXp.length; i++) {
    if (xp >= rankXp[i]) r = i;
  }
  return ranks[r];
}

class Prefs {
  static late SharedPreferences sp;
  static Future<void> init() async {
    sp = await SharedPreferences.getInstance();
  }

  static String get phase => sp.getString('phase') ?? '';
  static DateTime? get exam {
    final v = sp.getInt('exam');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  static String get dayType => sp.getString('day') ?? 'College Day';
  static List<String> get subjects => phases[phase] ?? phases.values.first;
  static Future<void> save(String phase, DateTime? exam) async {
    await sp.setString('phase', phase);
    if (exam != null) {
      await sp.setInt('exam', exam.millisecondsSinceEpoch);
    } else {
      await sp.remove('exam');
    }
  }

  static Future<void> setDay(String d) async {
    await sp.setString('day', d);
  }
}

class DB {
  static late Database db;
  static Future<void> init() async {
    db = await openDatabase(p.join(await getDatabasesPath(), 'pond.db'), version: 1, onCreate: (d, v) async {
      await d.execute('CREATE TABLE sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, start_ms INTEGER, dur_s INTEGER, subject TEXT, mode TEXT, goal TEXT, xp INTEGER, hy INTEGER)');
      await d.execute('CREATE TABLE pearls(id INTEGER PRIMARY KEY AUTOINCREMENT, subject TEXT, front TEXT, back TEXT, hy INTEGER, due_ms INTEGER, interval_d INTEGER, ease REAL, reps INTEGER, lapses INTEGER, created_ms INTEGER)');
      await d.execute('CREATE TABLE wins(id INTEGER PRIMARY KEY AUTOINCREMENT, ts_ms INTEGER, text TEXT)');
      await d.execute('CREATE TABLE mood(id INTEGER PRIMARY KEY AUTOINCREMENT, ts_ms INTEGER, score INTEGER)');
      await d.execute('CREATE TABLE attendance(subject TEXT PRIMARY KEY, held INTEGER, attended INTEGER)');
    });
  }

  static int midnight(DateTime t) => DateTime(t.year, t.month, t.day).millisecondsSinceEpoch;
  static int endOfToday() {
    final n = DateTime.now();
    return midnight(DateTime(n.year, n.month, n.day + 1)) - 1;
  }

  static Future<void> addSession(int startMs, int secs, String subject, String mode, String goal, int xp, bool hy) async {
    await db.insert('sessions', {'start_ms': startMs, 'dur_s': secs, 'subject': subject, 'mode': mode, 'goal': goal, 'xp': xp, 'hy': hy ? 1 : 0});
  }

  static Future<Map<int, int>> secsByDay(int days) async {
    final n = DateTime.now();
    final from = midnight(DateTime(n.year, n.month, n.day - (days - 1)));
    final r = await db.query('sessions', where: 'start_ms >= ?', whereArgs: [from]);
    final m = <int, int>{};
    for (final s in r) {
      final k = midnight(DateTime.fromMillisecondsSinceEpoch(s['start_ms'] as int));
      m[k] = (m[k] ?? 0) + (s['dur_s'] as int);
    }
    return m;
  }

  static int streakOf(Map<int, int> m) {
    final n = DateTime.now();
    var i = (m[midnight(DateTime(n.year, n.month, n.day))] ?? 0) < 600 ? 1 : 0;
    var s = 0;
    for (; i < 400; i++) {
      final k = midnight(DateTime(n.year, n.month, n.day - i));
      if ((m[k] ?? 0) >= 600) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }

  static Future<int> totalXp() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COALESCE(SUM(xp),0) FROM sessions')) ?? 0;

  static Future<List<Map<String, Object?>>> subjectSecs(int days) {
    final n = DateTime.now();
    final from = midnight(DateTime(n.year, n.month, n.day - (days - 1)));
    return db.rawQuery('SELECT subject, SUM(dur_s) AS s FROM sessions WHERE start_ms >= ? GROUP BY subject ORDER BY s DESC', [from]);
  }

  static Future<void> addPearl(String subject, String front, String back, bool hy) async {
    final now = DateTime.now();
    var due = now.add(const Duration(days: 1));
    final ex = Prefs.exam;
    if (ex != null) {
      final cap = ex.subtract(const Duration(days: 1));
      if (due.isAfter(cap) && cap.isAfter(now)) due = cap;
    }
    await db.insert('pearls', {'subject': subject, 'front': front, 'back': back, 'hy': hy ? 1 : 0, 'due_ms': due.millisecondsSinceEpoch, 'interval_d': 1, 'ease': 2.5, 'reps': 0, 'lapses': 0, 'created_ms': now.millisecondsSinceEpoch});
  }

  static Future<List<Map<String, Object?>>> duePearls() =>
      db.query('pearls', where: 'due_ms <= ?', whereArgs: [endOfToday()], orderBy: 'hy DESC, due_ms ASC');

  static Future<int> dueCount() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pearls WHERE due_ms <= ?', [endOfToday()])) ?? 0;

  // rating: 1 Again, 2 Hard, 3 Good, 4 Easy. Exam-aware: never schedules past exam-1 day.
  static Future<void> rate(Map<String, Object?> pr, int rating) async {
    var reps = pr['reps'] as int;
    final iv = pr['interval_d'] as int;
    var ease = (pr['ease'] as num).toDouble();
    var lapses = pr['lapses'] as int;
    const steps = [1, 3, 7, 21, 45];
    int next;
    if (rating == 1) {
      next = 1;
      reps = 0;
      lapses++;
      ease = max(1.3, ease - 0.2);
    } else if (rating == 2) {
      next = max(1, (iv * 1.2).round());
      ease = max(1.3, ease - 0.15);
    } else {
      next = reps < steps.length ? steps[reps] : (iv * ease).round();
      if (rating == 4) {
        next = (next * 1.4).round();
        ease += 0.1;
      }
      reps++;
    }
    final now = DateTime.now();
    var due = now.add(Duration(days: next));
    final ex = Prefs.exam;
    if (ex != null) {
      final cap = ex.subtract(const Duration(days: 1));
      if (due.isAfter(cap) && cap.isAfter(now)) due = cap;
    }
    await db.update('pearls', {'due_ms': due.millisecondsSinceEpoch, 'interval_d': next, 'ease': ease, 'reps': reps, 'lapses': lapses}, where: 'id = ?', whereArgs: [pr['id']]);
  }

  static Future<void> addWin(String t) async {
    await db.insert('wins', {'ts_ms': DateTime.now().millisecondsSinceEpoch, 'text': t});
  }

  static Future<List<Map<String, Object?>>> wins() => db.query('wins', orderBy: 'id DESC');

  static Future<void> addMood(int score) async {
    await db.insert('mood', {'ts_ms': DateTime.now().millisecondsSinceEpoch, 'score': score});
  }

  static Future<Map<String, List<int>>> allAtt() async {
    final r = await db.query('attendance');
    return {for (final x in r) (x['subject'] as String): [x['held'] as int, x['attended'] as int]};
  }

  static Future<void> bumpAtt(String s, bool present) async {
    final r = await db.query('attendance', where: 'subject = ?', whereArgs: [s]);
    if (r.isEmpty) {
      await db.insert('attendance', {'subject': s, 'held': 1, 'attended': present ? 1 : 0});
    } else {
      await db.update('attendance', {'held': (r.first['held'] as int) + 1, 'attended': (r.first['attended'] as int) + (present ? 1 : 0)}, where: 'subject = ?', whereArgs: [s]);
    }
  }
}
