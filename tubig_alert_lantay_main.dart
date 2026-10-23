import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WaterApp());
}

class WaterSource {
  int? id;
  String name;
  double level; // percent 0-100
  WaterSource({this.id, required this.name, required this.level});

  factory WaterSource.fromMap(Map<String, Object?> m) => WaterSource(
        id: m['id'] as int,
        name: m['name'] as String,
        level: (m['level'] as num).toDouble(),
      );

  String get status {
    if (level >= 60) return 'Normal';
    if (level >= 30) return 'Low';
    return 'Critical';
  }

  Color get color {
    if (level >= 60) return Colors.green;
    if (level >= 30) return Colors.orange;
    return Colors.red;
  }
}

class Schedule {
  int? id;
  String purok;
  String day;
  String time;
  Schedule({this.id, required this.purok, required this.day, required this.time});

  factory Schedule.fromMap(Map<String, Object?> m) => Schedule(
        id: m['id'] as int,
        purok: m['purok'] as String,
        day: m['day'] as String,
        time: m['time'] as String,
      );
}
class Report {
  int? id;
  String purok;
  String type;
  String details;
  Report({this.id, required this.purok, required this.type, required this.details});

  factory Report.fromMap(Map<String, Object?> m) => Report(
        id: m['id'] as int,
        purok: m['purok'] as String,
        type: m['type'] as String,
        details: m['details'] as String,
      );
}

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'lantay_water.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('CREATE TABLE sources('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, level REAL)');
        await d.execute('CREATE TABLE schedules('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, purok TEXT, day TEXT, time TEXT)');
        await d.execute('CREATE TABLE reports('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, purok TEXT, type TEXT, details TEXT)');
        // Starting sample data
        await d.insert('sources', {'name': 'Main Water Tank', 'level': 78.0});
        await d.insert('sources', {'name': 'Spring Source', 'level': 45.0});
        await d.insert('sources', {'name': 'Purok 3 Reservoir', 'level': 22.0});
        await d.insert('schedules',
            {'purok': 'Purok 1', 'day': 'Monday', 'time': '6:00 AM - 9:00 AM'});
        await d.insert('schedules',
            {'purok': 'Purok 2', 'day': 'Tuesday', 'time': '6:00 AM - 9:00 AM'});
        await d.insert('schedules',
            {'purok': 'Purok 3', 'day': 'Wednesday', 'time': '5:00 PM - 8:00 PM'});
      },
    );
  }

  Future<List<WaterSource>> getSources() async {
    final d = await db;
    return (await d.query('sources', orderBy: 'id')).map(WaterSource.fromMap).toList();
  }

  Future<void> updateSourceLevel(int id, double level) async {
    final d = await db;
    await d.update('sources', {'level': level}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Schedule>> getSchedules() async {
    final d = await db;
    return (await d.query('schedules', orderBy: 'id')).map(Schedule.fromMap).toList();
  }

  Future<void> addSchedule(Schedule s) async {
    final d = await db;
    await d.insert('schedules', {'purok': s.purok, 'day': s.day, 'time': s.time});
  }

  Future<void> deleteSchedule(int id) async {
    final d = await db;
    await d.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Report>> getReports() async {
    final d = await db;
    return (await d.query('reports', orderBy: 'id DESC')).map(Report.fromMap).toList();
  }

  Future<void> addReport(Report r) async {
    final d = await db;
    await d.insert('reports', {'purok': r.purok, 'type': r.type, 'details': r.details});
  }
}

class WaterApp extends StatelessWidget {
  const WaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lantay Water System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePass = true;

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    if (_userCtrl.text.trim() == 'admin' && _passCtrl.text == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.water_drop, size: 80, color: Colors.blue),
                const SizedBox(height: 8),
                const Text(
                  'Barangay Lantay\nWater Supply System',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _hidePass,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _hidePass ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _hidePass = !_hidePass),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter password' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _login,
                    child: const Text('LOG IN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  bool _loading = true;
  List<WaterSource> sources = [];
  List<Schedule> schedules = [];
  List<Report> reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Reads everything from the SQLite database and refreshes the screen
  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final s = await db.getSources();
    final sc = await db.getSchedules();
    final r = await db.getReports();
    if (!mounted) return;
    setState(() {
      sources = s;
      schedules = sc;
      reports = r;
      _loading = false;
    });
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(sources: sources, schedules: schedules, reports: reports),
      MonitoringPage(sources: sources, onChanged: _load),
      DistributionPage(schedules: schedules, onChanged: _load),
      ReportsPage(reports: reports, onChanged: _load),
    ];
    const titles = ['Dashboard', 'Monitoring', 'Distribution', 'Reports'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.water), label: 'Monitor'),
          NavigationDestination(
              icon: Icon(Icons.local_shipping), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.report), label: 'Reports'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final List<WaterSource> sources;
  final List<Schedule> schedules;
  final List<Report> reports;

  const DashboardPage({
    super.key,
    required this.sources,
    required this.schedules,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    final avg = sources.isEmpty
        ? 0.0
        : sources.map((s) => s.level).reduce((a, b) => a + b) / sources.length;
    final critical = sources.where((s) => s.status == 'Critical').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Average Water Level',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('${avg.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: avg / 100, minHeight: 10),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stat('Sources', '${sources.length}', Icons.water_drop, Colors.blue),
            _stat('Critical', '$critical', Icons.warning, Colors.red),
          ],
        ),
        Row(
          children: [
            _stat('Schedules', '${schedules.length}', Icons.schedule,
                Colors.green),
            _stat('Reports', '${reports.length}', Icons.report, Colors.orange),
          ],
        ),
        if (critical > 0)
          Card(
            color: Colors.red.shade50,
            child: const ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Water level alert'),
              subtitle: Text('One or more sources are at a critical level.'),
            ),
          ),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class MonitoringPage extends StatelessWidget {
  final List<WaterSource> sources;
  final VoidCallback onChanged;

  const MonitoringPage(
      {super.key, required this.sources, required this.onChanged});

  void _updateLevel(BuildContext context, WaterSource s) {
    double temp = s.level;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Update ${s.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${temp.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 28)),
              Slider(
                value: temp,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (v) => setD(() => temp = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await DatabaseHelper.instance.updateSourceLevel(s.id!, temp);
                onChanged();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sources.length,
      itemBuilder: (context, i) {
        final s = sources[i];
        return Card(
          child: ListTile(
            leading: Icon(Icons.water_drop, color: s.color, size: 36),
            title: Text(s.name),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                      value: s.level / 100, color: s.color, minHeight: 8),
                  const SizedBox(height: 4),
                  Text('${s.level.toStringAsFixed(0)}% - ${s.status}'),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _updateLevel(context, s),
            ),
          ),
        );
      },
    );
  }
}

class DistributionPage extends StatelessWidget {
  final List<Schedule> schedules;
  final VoidCallback onChanged;

  const DistributionPage(
      {super.key, required this.schedules, required this.onChanged});

  void _addSchedule(BuildContext context) {
    final purok = TextEditingController();
    final day = TextEditingController();
    final time = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Distribution Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: purok,
                decoration: const InputDecoration(labelText: 'Purok')),
            TextField(
                controller: day,
                decoration: const InputDecoration(labelText: 'Day')),
            TextField(
                controller: time,
                decoration: const InputDecoration(labelText: 'Time')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (purok.text.trim().isEmpty ||
                  day.text.trim().isEmpty ||
                  time.text.trim().isEmpty) {
                return;
              }
              await DatabaseHelper.instance.addSchedule(Schedule(
                  purok: purok.text.trim(),
                  day: day.text.trim(),
                  time: time.text.trim()));
              onChanged();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: schedules.isEmpty
          ? const Center(child: Text('No schedules yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: schedules.length,
              itemBuilder: (context, i) {
                final s = schedules[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping),
                    title: Text(s.purok),
                    subtitle: Text('${s.day} - ${s.time}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteSchedule(s.id!);
                        onChanged();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSchedule(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReportsPage extends StatefulWidget {
  final List<Report> reports;
  final VoidCallback onChanged;

  const ReportsPage({super.key, required this.reports, required this.onChanged});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _formKey = GlobalKey<FormState>();
  final _purok = TextEditingController();
  final _details = TextEditingController();
  String _type = 'No Water';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await DatabaseHelper.instance.addReport(Report(
        purok: _purok.text.trim(), type: _type, details: _details.text.trim()));
    widget.onChanged();
    _purok.clear();
    _details.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Report submitted')));
  }

  @override
  void dispose() {
    _purok.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _purok,
                decoration: const InputDecoration(
                    labelText: 'Purok', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter purok' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                    labelText: 'Issue type', border: OutlineInputBorder()),
                items: const ['No Water', 'Leak', 'Low Pressure', 'Dirty Water']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _details,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Details', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter details' : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _submit, child: const Text('SUBMIT REPORT')),
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        const Text('Submitted Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.reports.map((r) => Card(
              child: ListTile(
                leading: const Icon(Icons.report_problem, color: Colors.orange),
                title: Text('${r.type} - ${r.purok}'),
                subtitle: Text(r.details),
              ),
            )),
      ],
    );
  }
}
