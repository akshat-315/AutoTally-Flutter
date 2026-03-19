import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/categories.dart';
import 'tables/merchants.dart';
import 'tables/transactions.dart';
import 'tables/templates.dart';
import 'tables/app_config.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Categories, Merchants, Transactions, Templates, AppConfig],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedCategories();
      await _seedTemplates();
    },
  );

  Future<void> _seedCategories() async {
    final defaults = [
      ('Food', '🍔', '#FF6B35'),
      ('Transport', '🚗', '#4ECDC4'),
      ('Shopping', '🛍️', '#E91E63'),
      ('Bills', '📄', '#607D8B'),
      ('Entertainment', '🎬', '#9C27B0'),
      ('Health', '💊', '#4CAF50'),
      ('Education', '📚', '#2196F3'),
      ('Transfers', '🔄', '#78909C'),
      ('Subscriptions', '🔁', '#FF9800'),
      ('Other', '📦', '#9E9E9E'),
    ];

    for (final (name, icon, color) in defaults) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: name,
          icon: icon,
          color: color,
          isDefault: const Value(true),
        ),
      );
    }
  }

  Future<void> _seedTemplates() async {
    final jsonStr = await rootBundle.loadString('assets/sms_templates.json');
    final Map<String, dynamic> data = json.decode(jsonStr);

    for (final entry in data.entries) {
      if (entry.key.startsWith('_')) continue;
      final bankConfig = entry.value as Map<String, dynamic>;
      final senderKey = entry.key;
      final bankName = bankConfig['bank'] as String;
      final templateList = bankConfig['templates'] as List;

      for (final tmpl in templateList) {
        await into(templates).insert(
          TemplatesCompanion.insert(
            senderKey: senderKey,
            bankName: bankName,
            direction: tmpl['direction'] as String,
            pattern: tmpl['pattern'] as String,
            source: tmpl['source'] as String? ?? 'bundled',
          ),
        );
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'autotally.db'));
    return NativeDatabase.createInBackground(file);
  });
}
