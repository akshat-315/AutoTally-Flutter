import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/services/sms_parser/template_engine.dart';
import 'package:autotally_flutter/services/sms_reader/sms_reader_service.dart';

late AppDatabase database;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoTally',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SmsTestScreen(),
    );
  }
}

class SmsTestScreen extends StatefulWidget {
  const SmsTestScreen({super.key});

  @override
  State<SmsTestScreen> createState() => _SmsTestScreenState();
}

class _SmsTestScreenState extends State<SmsTestScreen> {
  String _status = 'Tap the button to scan SMS';
  final List<String> _results = [];

  Future<void> _scanSms() async {
    setState(() {
      _status = 'Requesting permission...';
      _results.clear();
    });

    final permission = await Permission.sms.request();
    if (!permission.isGranted) {
      setState(() => _status = 'SMS permission denied');
      return;
    }

    setState(() => _status = 'Reading SMS...');

    final engine = TemplateEngine(database);
    final reader = SmsReaderService(engine);
    final result = await reader.readAndParseAll();

    setState(() {
      _status = 'Found ${result.parsed.length} transactions';
      for (final tx in result.parsed) {
        final d = tx.data;
        final amountRupees = (d.amount / 100).toStringAsFixed(2);
        _results.add(
          '${d.direction.toUpperCase()} | Rs.$amountRupees | ${d.merchantRaw ?? "unknown"} | ${d.bank} | ${d.transactionDate?.toString().substring(0, 10) ?? "no date"}',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AutoTally - SMS Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_results[index]),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanSms,
        child: const Icon(Icons.sms),
      ),
    );
  }
}
