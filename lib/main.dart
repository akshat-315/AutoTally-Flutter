import 'package:flutter/material.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/repositories/app_config_repository.dart';
import 'package:autotally_flutter/services/transaction_query_service.dart';
import 'package:autotally_flutter/services/sms_parser/template_engine.dart';
import 'package:autotally_flutter/services/merchant_resolver/merchant_resolver.dart';
import 'package:autotally_flutter/services/sms_listener/sms_listener_service.dart';
import 'package:autotally_flutter/repositories/transaction_repository.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/screens/shell/app_shell.dart';
import 'package:autotally_flutter/screens/splash/splash_screen.dart';
import 'package:autotally_flutter/screens/onboarding/onboarding_screen.dart';

late AppDatabase database;
late TransactionQueryService queryService;
late SmsListenerService smsListener;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  queryService = TransactionQueryService(database);
  final engine = TemplateEngine(database);
  final resolver = MerchantResolver(database);
  final txnRepo = TransactionRepository(database);
  smsListener = SmsListenerService(database, engine, resolver, txnRepo);
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

class _AppEntryState extends State<_AppEntry> with WidgetsBindingObserver {
  bool _showSplash = true;
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboarding();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    smsListener.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _onboardingComplete == true) {
      smsListener.startListening();
      smsListener.catchUpScan();
    }
  }

  Future<void> _checkOnboarding() async {
    final config = AppConfigRepository(database);
    final complete = await config.getBool('onboarding_complete');
    if (complete) {
      await _loadCategories();
      smsListener.startListening();
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
              smsListener.startListening();
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
