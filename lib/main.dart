import 'package:flutter/material.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/screens/shell/app_shell.dart';

late AppDatabase database;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  runApp(const AutoTallyApp());
}

class AutoTallyApp extends StatelessWidget {
  const AutoTallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoTally',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const AppShell(),
    );
  }
}
