import 'package:drift/drift.dart';
import 'package:rapidfuzz/rapidfuzz.dart';
import 'package:autotally_flutter/database/database.dart';

const _stripSuffixes = [
  'PVT',
  'LTD',
  'PRIVATE',
  'LIMITED',
  'TECHNOLOGIES',
  'TECH',
  'INDIA',
  'SYSTEMS',
  'SERVICES',
  'SOLUTIONS',
  'ENTERPRISES',
  'CORPORATION',
  'CORP',
  'INC',
];

const _fuzzyThreshold = 85;

String normalizeMerchantName(String raw) {
  var name = raw.toUpperCase().trim();
  name = name.replaceAll(RegExp(r'[^\w\s]'), '');
  final words = name.split(RegExp(r'\s+'));
  final filtered = words.where((w) => !_stripSuffixes.contains(w)).toList();
  return filtered.join(' ').trim();
}

class MerchantResolver {
  final AppDatabase _db;

  MerchantResolver(this._db);

  Future<int> resolve(String? merchantRaw) async {
    if (merchantRaw == null || merchantRaw.trim().isEmpty) {
      return _createMerchant(merchantRaw ?? 'Unknown', 'auto');
    }

    final normalized = normalizeMerchantName(merchantRaw);

    final exactMatch = await _findExactAlias(normalized);
    if (exactMatch != null) {
      await _updateLastSeen(exactMatch);
      return exactMatch;
    }

    final fuzzyMatch = await _findFuzzyAlias(normalized);
    if (fuzzyMatch != null) {
      final sourceMerchant = await (_db.select(_db.merchants)
            ..where((m) => m.id.equals(fuzzyMatch)))
          .getSingle();
      return _createMerchant(
        merchantRaw,
        'fuzzy',
        categoryId: sourceMerchant.categoryId,
        normalizedAlias: normalized,
      );
    }

    return _createMerchant(merchantRaw, 'auto', normalizedAlias: normalized);
  }

  Future<int?> _findExactAlias(String normalized) async {
    final result = await (_db.select(_db.merchantAliases)
          ..where((a) => a.alias.equals(normalized)))
        .getSingleOrNull();
    return result?.merchantId;
  }

  Future<int?> _findFuzzyAlias(String normalized) async {
    final allAliases = await _db.select(_db.merchantAliases).get();
    int? bestMerchantId;
    double bestScore = 0;

    for (final alias in allAliases) {
      final score = tokenSortRatio(normalized, alias.alias);
      if (score >= _fuzzyThreshold && score > bestScore) {
        bestScore = score;
        bestMerchantId = alias.merchantId;
      }
    }

    return bestMerchantId;
  }

  Future<int> _createMerchant(
    String rawName,
    String source, {
    int? categoryId,
    String? normalizedAlias,
  }) async {
    final merchantId = await _db.into(_db.merchants).insert(
          MerchantsCompanion.insert(
            name: rawName,
            source: Value(source),
            categoryId: Value(categoryId),
            lastSeen: Value(DateTime.now()),
          ),
        );

    final alias = normalizedAlias ?? normalizeMerchantName(rawName);
    if (alias.isNotEmpty) {
      await _db.into(_db.merchantAliases).insert(
            MerchantAliasesCompanion.insert(
              merchantId: merchantId,
              alias: alias,
            ),
          );
    }

    return merchantId;
  }

  Future<void> _updateLastSeen(int merchantId) async {
    await (_db.update(_db.merchants)..where((m) => m.id.equals(merchantId)))
        .write(MerchantsCompanion(lastSeen: Value(DateTime.now())));
  }
}
