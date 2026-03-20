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
import 'tables/merchant_aliases.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Categories, Merchants, Transactions, Templates, AppConfig, MerchantAliases],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedCategories();
      await _seedTemplates();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await customStatement('ALTER TABLE merchants RENAME COLUMN is_p2p TO auto_categorize');
        await customStatement('UPDATE merchants SET auto_categorize = CASE WHEN auto_categorize = 0 THEN 1 ELSE 0 END');
      }
      if (from < 3) {
        await customStatement(
          "INSERT OR IGNORE INTO categories (name, icon, color, is_default) "
          "VALUES ('Uncategorized', '❓', '#9E9E9E', 1)"
        );
        await customStatement(
          "UPDATE transactions SET category_id = "
          "(SELECT id FROM categories WHERE name = 'Uncategorized'), "
          "category_source = 'default' "
          "WHERE category_id IS NULL"
        );
      }
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
      ('Uncategorized', '❓', '#9E9E9E'),
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
      final bankName = bankConfig['bank'] as String;
      final senderIds = (bankConfig['sender_ids'] as List?)
              ?.cast<String>() ??
          [entry.key];
      final templateList = bankConfig['templates'] as List;

      for (final senderId in senderIds) {
        for (final tmpl in templateList) {
          await into(templates).insert(
            TemplatesCompanion.insert(
              senderKey: senderId,
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'autotally.db'));
    return NativeDatabase.createInBackground(file);
  });
}
