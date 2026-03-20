import 'package:flutter/material.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/repositories/app_config_repository.dart';
import 'package:autotally_flutter/services/transaction_query_service.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/screens/shell/app_shell.dart';
import 'package:autotally_flutter/screens/splash/splash_screen.dart';
import 'package:autotally_flutter/screens/onboarding/onboarding_screen.dart';

late AppDatabase database;
late TransactionQueryService queryService;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  queryService = TransactionQueryService(database);
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
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _showSplash = true;
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final config = AppConfigRepository(database);
    final complete = await config.getBool('onboarding_complete');
    if (complete) {
      await _loadCategories();
    }
    if (mounted) {
      setState(() => _onboardingComplete = complete);
    }
  }

  Future<void> _loadCategories() async {
    final cats = await queryService.getCategories();
    PlaceholderData.categories
      ..clear()
      ..addAll(cats);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_onboardingComplete == true)
          const AppShell()
        else if (_onboardingComplete == false)
          OnboardingScreen(
            onComplete: () async {
              await _loadCategories();
              if (mounted) setState(() => _onboardingComplete = true);
            },
          ),
        if (_showSplash)
          SplashScreen(
            onComplete: () => setState(() => _showSplash = false),
          ),
      ],
    );
  }
}
