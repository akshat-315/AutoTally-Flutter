import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';

class TransactionQueryService {
  final AppDatabase _db;
  List<MockCategory>? _categoriesCache;

  TransactionQueryService(this._db);

  Future<List<MockCategory>> getCategories() async {
    if (_categoriesCache != null) return _categoriesCache!;
    final rows = await _db.select(_db.categories).get();
    _categoriesCache = rows.map((c) => MockCategory(
      id: c.id,
      name: c.name,
      icon: c.icon,
      color: _parseColor(c.color),
      isDefault: c.isDefault,
    )).toList();
    return _categoriesCache!;
  }

  void invalidateCategoryCache() => _categoriesCache = null;

  Future<MockCategory?> getCategoryById(int? id) async {
    if (id == null) return null;
    final cats = await getCategories();
    return cats.where((c) => c.id == id).firstOrNull;
  }

  Future<List<MockTransaction>> transactionsForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final txns = await (_db.select(_db.transactions)
      ..where((t) => t.transactionDate.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
    ).get();

    final merchants = await _db.select(_db.merchants).get();
    final merchantMap = {for (var m in merchants) m.id: m};

    return txns.map((t) => _toView(t, merchantMap)).toList();
  }

  Future<List<MockTransaction>> transactionsForToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final txns = await (_db.select(_db.transactions)
      ..where((t) => t.transactionDate.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
    ).get();

    final merchants = await _db.select(_db.merchants).get();
    final merchantMap = {for (var m in merchants) m.id: m};

    return txns.map((t) => _toView(t, merchantMap)).toList();
  }

  Future<({int spent, int count})> todayStats() async {
    final txns = await transactionsForToday();
    final spent = txns
        .where((t) => t.direction == 'debit')
        .fold(0, (sum, t) => sum + t.amount);
    return (spent: spent, count: txns.length);
  }

  Future<int> totalSpentForMonth(int year, int month) async {
    final txns = await transactionsForMonth(year, month);
    return txns
        .where((t) => t.direction == 'debit' && !t.isP2p)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  Future<List<MockTransaction>> triageTransactions() async {
    final txns = await (_db.select(_db.transactions)
      ..where((t) => t.categoryId.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
    ).get();

    final merchants = await _db.select(_db.merchants).get();
    final merchantMap = {for (var m in merchants) m.id: m};

    return txns.map((t) => _toView(t, merchantMap)).toList();
  }

  Future<List<({MockCategory category, int total})>> spendByCategoryForMonth(
      int year, int month) async {
    final txns = await transactionsForMonth(year, month);
    final categories = await getCategories();
    final catMap = {for (var c in categories) c.id: c};

    final totals = <int, int>{};
    for (final t in txns) {
      if (t.direction == 'debit' && !t.isP2p && t.categoryId != null) {
        totals.update(t.categoryId!, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }

    final result = totals.entries
        .where((e) => catMap.containsKey(e.key))
        .map((e) => (category: catMap[e.key]!, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return result;
  }

  Future<MockMerchant?> getMerchantById(int? id) async {
    if (id == null) return null;
    final row = await (_db.select(_db.merchants)
      ..where((m) => m.id.equals(id))
    ).getSingleOrNull();
    if (row == null) return null;

    final txns = await (_db.select(_db.transactions)
      ..where((t) => t.merchantId.equals(id))
    ).get();

    final totalSpent = txns
        .where((t) => t.direction == 'debit')
        .fold<int>(0, (sum, t) => sum + t.amount);

    return MockMerchant(
      id: row.id,
      name: row.name,
      displayName: row.displayName,
      vpa: row.vpa,
      categoryId: row.categoryId,
      autoCategorize: row.autoCategorize,
      transactionCount: txns.length,
      totalSpent: totalSpent,
    );
  }

  Future<List<MockMerchant>> getAllMerchants() async {
    final merchants = await _db.select(_db.merchants).get();
    final allTxns = await _db.select(_db.transactions).get();

    final txnCounts = <int, int>{};
    final txnTotals = <int, int>{};
    for (final t in allTxns) {
      if (t.merchantId == null) continue;
      txnCounts.update(t.merchantId!, (v) => v + 1, ifAbsent: () => 1);
      if (t.direction == 'debit') {
        txnTotals.update(t.merchantId!, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }

    return merchants.map((m) => MockMerchant(
      id: m.id,
      name: m.name,
      displayName: m.displayName,
      vpa: m.vpa,
      categoryId: m.categoryId,
      autoCategorize: m.autoCategorize,
      transactionCount: txnCounts[m.id] ?? 0,
      totalSpent: txnTotals[m.id] ?? 0,
    )).toList();
  }

  Future<List<MockTransaction>> transactionsForMerchant(int merchantId) async {
    final txns = await (_db.select(_db.transactions)
      ..where((t) => t.merchantId.equals(merchantId))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
    ).get();

    final merchants = await _db.select(_db.merchants).get();
    final merchantMap = {for (var m in merchants) m.id: m};

    return txns.map((t) => _toView(t, merchantMap)).toList();
  }

  Future<({int spent, int received, int txCount, int debitCount, int creditCount})>
      monthStats(int year, int month) async {
    final txns = await transactionsForMonth(year, month);
    final debits = txns.where((t) => t.direction == 'debit' && !t.isP2p);
    final credits = txns.where((t) => t.direction == 'credit' && !t.isP2p);
    return (
      spent: debits.fold<int>(0, (sum, t) => sum + t.amount),
      received: credits.fold<int>(0, (sum, t) => sum + t.amount),
      txCount: txns.length,
      debitCount: txns.where((t) => t.direction == 'debit').length,
      creditCount: txns.where((t) => t.direction == 'credit').length,
    );
  }

  Future<Map<int, int>> dailySpendForMonth(int year, int month) async {
    final txns = await transactionsForMonth(year, month);
    final daily = <int, int>{};
    for (final t in txns) {
      if (t.direction == 'debit') {
        daily.update(t.date.day, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }
    return daily;
  }

  Future<Map<int, int>> cumulativeDailySpend(int year, int month) async {
    final daily = await dailySpendForMonth(year, month);
    final days = DateTime(year, month + 1, 0).day;
    final cumulative = <int, int>{};
    int running = 0;
    for (int d = 1; d <= days; d++) {
      running += daily[d] ?? 0;
      cumulative[d] = running;
    }
    return cumulative;
  }

  Future<List<({String name, int total, int count})>> topMerchantsForMonth(
      int year, int month, {int limit = 5}) async {
    final txns = await transactionsForMonth(year, month);
    final totals = <int, int>{};
    final counts = <int, int>{};
    final names = <int, String>{};

    for (final t in txns) {
      if (t.direction == 'debit' && !t.isP2p && t.merchantId != null) {
        totals.update(t.merchantId!, (v) => v + t.amount, ifAbsent: () => t.amount);
        counts.update(t.merchantId!, (v) => v + 1, ifAbsent: () => 1);
        names.putIfAbsent(t.merchantId!, () => t.merchantName);
      }
    }

    final result = totals.entries
        .map((e) => (name: names[e.key]!, total: e.value, count: counts[e.key]!))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return result.take(limit).toList();
  }

  Future<Map<int, int>> dayOfWeekTotals(int year, int month) async {
    final txns = await transactionsForMonth(year, month);
    final totals = <int, int>{};
    for (final t in txns) {
      if (t.direction == 'debit') {
        final dow = t.date.weekday;
        totals.update(dow, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }
    return totals;
  }

  Future<List<({DateTime month, int spent, int income})>> monthlyTrend(
      int currentYear, int currentMonth, {int months = 6}) async {
    final result = <({DateTime month, int spent, int income})>[];
    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(currentYear, currentMonth - i);
      final stats = await monthStats(m.year, m.month);
      result.add((month: m, spent: stats.spent, income: stats.received));
    }
    return result;
  }

  Future<List<MockTransaction>> recentTransactions({int limit = 5}) async {
    final txns = await (_db.select(_db.transactions)
      ..where((t) => t.transactionDate.isSmallerOrEqualValue(DateTime.now()))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
      ..limit(limit)
    ).get();

    final merchants = await _db.select(_db.merchants).get();
    final merchantMap = {for (var m in merchants) m.id: m};

    return txns.map((t) => _toView(t, merchantMap)).toList();
  }

  Future<List<MockTransaction>> transactionsForRange(
      DateTime start, DateTime end) async {
    final txns = await (_db.select(_db.transactions)
      ..where((t) => t.transactionDate.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
    ).get();

    final merchants = await _db.select(_db.merchants).get();
    final merchantMap = {for (var m in merchants) m.id: m};

    return txns.map((t) => _toView(t, merchantMap)).toList();
  }

  Future<({int spent, int received, int txCount, int debitCount, int creditCount})>
      rangeStats(DateTime start, DateTime end) async {
    final txns = await transactionsForRange(start, end);
    final debits = txns.where((t) => t.direction == 'debit' && !t.isP2p);
    final credits = txns.where((t) => t.direction == 'credit' && !t.isP2p);
    return (
      spent: debits.fold<int>(0, (sum, t) => sum + t.amount),
      received: credits.fold<int>(0, (sum, t) => sum + t.amount),
      txCount: txns.length,
      debitCount: txns.where((t) => t.direction == 'debit').length,
      creditCount: txns.where((t) => t.direction == 'credit').length,
    );
  }

  Future<List<({MockCategory category, int total})>> spendByCategoryForRange(
      DateTime start, DateTime end) async {
    final txns = await transactionsForRange(start, end);
    final categories = await getCategories();
    final catMap = {for (var c in categories) c.id: c};

    final totals = <int, int>{};
    for (final t in txns) {
      if (t.direction == 'debit' && !t.isP2p && t.categoryId != null) {
        totals.update(t.categoryId!, (v) => v + t.amount,
            ifAbsent: () => t.amount);
      }
    }

    final result = totals.entries
        .where((e) => catMap.containsKey(e.key))
        .map((e) => (category: catMap[e.key]!, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return result;
  }

  Future<List<({String name, int total, int count})>> topMerchantsForRange(
      DateTime start, DateTime end, {int limit = 5}) async {
    final txns = await transactionsForRange(start, end);
    final totals = <int, int>{};
    final counts = <int, int>{};
    final names = <int, String>{};

    for (final t in txns) {
      if (t.direction == 'debit' && !t.isP2p && t.merchantId != null) {
        totals.update(t.merchantId!, (v) => v + t.amount,
            ifAbsent: () => t.amount);
        counts.update(t.merchantId!, (v) => v + 1, ifAbsent: () => 1);
        names.putIfAbsent(t.merchantId!, () => t.merchantName);
      }
    }

    final result = totals.entries
        .map((e) => (name: names[e.key]!, total: e.value, count: counts[e.key]!))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return result.take(limit).toList();
  }

  Future<Map<int, int>> cumulativeDailySpendForRange(
      DateTime start, DateTime end) async {
    final txns = await transactionsForRange(start, end);
    final totalDays = end.difference(start).inDays + 1;
    final daily = <int, int>{};

    for (final t in txns) {
      if (t.direction == 'debit') {
        final dayIndex = t.date.difference(start).inDays + 1;
        daily.update(dayIndex, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }

    final cumulative = <int, int>{};
    int running = 0;
    for (int d = 1; d <= totalDays; d++) {
      running += daily[d] ?? 0;
      cumulative[d] = running;
    }
    return cumulative;
  }

  Future<Map<int, int>> dayOfWeekTotalsForRange(
      DateTime start, DateTime end) async {
    final txns = await transactionsForRange(start, end);
    final totals = <int, int>{};
    for (final t in txns) {
      if (t.direction == 'debit') {
        final dow = t.date.weekday;
        totals.update(dow, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }
    return totals;
  }

  Future<List<({DateTime month, int spent, int income})>> trendForRange(
      DateTime start, DateTime end) async {
    final rangeDays = end.difference(start).inDays;

    if (rangeDays < 60) {
      final weekCount = (rangeDays / 7).ceil().clamp(1, 12);
      final result = <({DateTime month, int spent, int income})>[];
      var weekStart = start;
      for (int i = 0; i < weekCount; i++) {
        var weekEnd = weekStart.add(const Duration(days: 6));
        if (weekEnd.isAfter(end)) weekEnd = end;
        final wEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
        final stats = await rangeStats(weekStart, wEnd);
        result.add((month: weekStart, spent: stats.spent, income: stats.received));
        weekStart = weekEnd.add(const Duration(days: 1));
        if (weekStart.isAfter(end)) break;
      }
      return result;
    }

    final result = <({DateTime month, int spent, int income})>[];
    var current = DateTime(start.year, start.month);
    final endMonth = DateTime(end.year, end.month);
    while (!current.isAfter(endMonth)) {
      final mStart = current.isBefore(start) ? start : current;
      final mEnd = DateTime(current.year, current.month + 1, 0, 23, 59, 59);
      final actualEnd = mEnd.isAfter(end) ? end : mEnd;
      final stats = await rangeStats(mStart, actualEnd);
      result.add((month: current, spent: stats.spent, income: stats.received));
      current = DateTime(current.year, current.month + 1);
    }
    return result;
  }

  Future<void> updateTransactionCategory(int transactionId, int categoryId) async {
    await (_db.update(_db.transactions)
      ..where((t) => t.id.equals(transactionId))
    ).write(TransactionsCompanion(
      categoryId: Value(categoryId),
      categorySource: const Value('user'),
    ));
  }

  Future<void> updateMerchantCategory(int merchantId, int categoryId) async {
    await _db.transaction(() async {
      await (_db.update(_db.merchants)
        ..where((m) => m.id.equals(merchantId))
      ).write(MerchantsCompanion(
        categoryId: Value(categoryId),
      ));

      await (_db.update(_db.transactions)
        ..where((t) => t.merchantId.equals(merchantId))
      ).write(TransactionsCompanion(
        categoryId: Value(categoryId),
        categorySource: const Value('merchant'),
      ));
    });
  }

  Future<void> updateMerchantDisplayName(int merchantId, String displayName) async {
    await (_db.update(_db.merchants)
      ..where((m) => m.id.equals(merchantId))
    ).write(MerchantsCompanion(
      displayName: Value(displayName),
    ));
  }

  Future<void> updateMerchantAutoCategorize(int merchantId, bool autoCategorize) async {
    await (_db.update(_db.merchants)
      ..where((m) => m.id.equals(merchantId))
    ).write(MerchantsCompanion(
      autoCategorize: Value(autoCategorize),
    ));
  }

  Future<bool> getMerchantAutoCategorize(int merchantId) async {
    final row = await (_db.select(_db.merchants)
      ..where((m) => m.id.equals(merchantId))
    ).getSingleOrNull();
    return row?.autoCategorize ?? true;
  }

  MockTransaction _toView(Transaction t, Map<int, Merchant> merchantMap) {
    final merchant = t.merchantId != null ? merchantMap[t.merchantId] : null;
    final isP2p = t.isP2p ||
        (t.vpa != null && RegExp(r'^\d{10,}@').hasMatch(t.vpa!));

    return MockTransaction(
      id: t.id,
      direction: t.direction,
      amount: t.amount,
      merchantName: merchant?.displayName ?? merchant?.name ?? t.merchantRaw ?? 'Unknown',
      vpa: t.vpa,
      categoryId: t.categoryId,
      categorySource: t.categorySource,
      bank: t.bank,
      accountLast4: t.accountLast4,
      date: t.transactionDate,
      isP2p: isP2p,
      upiRef: t.upiRef,
      rawSms: t.rawSms,
      smsSender: t.smsSender,
      merchantId: t.merchantId,
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
