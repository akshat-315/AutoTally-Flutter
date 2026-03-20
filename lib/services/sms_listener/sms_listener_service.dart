import 'dart:async';

import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/services/sms_parser/template_engine.dart';
import 'package:autotally_flutter/services/merchant_resolver/merchant_resolver.dart';
import 'package:autotally_flutter/services/sms_reader/sms_reader_service.dart';
import 'package:autotally_flutter/repositories/transaction_repository.dart';

typedef OnTransactionSaved = void Function(int transactionId);

class SmsListenerService {
  static const _channel = EventChannel('com.autotally/sms_receiver');

  final AppDatabase _db;
  final TemplateEngine _engine;
  final MerchantResolver _resolver;
  final TransactionRepository _txnRepo;

  StreamSubscription? _subscription;
  OnTransactionSaved? onTransactionSaved;
  bool _catchUpRunning = false;

  static final _financialPattern = RegExp(
    r'(rs\.?\s?\d|inr\s?\d|debited|credited|spent|withdrawn|deposited|transferred|upi\s|neft|imps|a/c\s|your\sa/c)',
    caseSensitive: false,
  );

  SmsListenerService(this._db, this._engine, this._resolver, this._txnRepo);

  void startListening() {
    _subscription?.cancel();
    _subscription = _channel.receiveBroadcastStream().listen(_handleSms);
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  static bool _isTransactionalSender(String address) {
    final cleaned = address.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'[a-zA-Z]{2,}').hasMatch(cleaned) &&
        !RegExp(r'^\+?\d{10,}$').hasMatch(cleaned);
  }

  Future<void> _handleSms(dynamic event) async {
    if (event is! Map) return;

    final sender = event['sender'] as String?;
    final body = event['body'] as String?;
    final timestamp = event['timestamp'] as int?;

    if (sender == null || body == null) return;
    if (!_isTransactionalSender(sender)) return;
    if (!_financialPattern.hasMatch(body)) return;

    await _processRawSms(sender, body, timestamp);
  }

  Future<int?> _processRawSms(String sender, String body, int? timestamp) async {
    try {
      final parsed = await _engine.parseSms(sender, body);
      if (parsed == null) return null;

      final existing = await (_db.select(_db.transactions)
            ..where((t) => t.rawSms.equals(body))
            ..where((t) => t.smsSender.equals(sender)))
          .getSingleOrNull();
      if (existing != null) return null;

      final merchantId = await _resolver.resolve(parsed.merchantRaw);

      int? categoryId;
      String? categorySource;
      {
        final merchant = await (_db.select(_db.merchants)
              ..where((m) => m.id.equals(merchantId)))
            .getSingleOrNull();
        if (merchant?.categoryId != null) {
          categoryId = merchant!.categoryId;
          categorySource = 'merchant';
        }
      }
      if (categoryId == null) {
        final uncategorized = await (_db.select(_db.categories)
              ..where((c) => c.name.equals('Uncategorized')))
            .getSingleOrNull();
        if (uncategorized != null) {
          categoryId = uncategorized.id;
          categorySource = 'default';
        }
      }

      final receivedAt = timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : DateTime.now();

      final id = await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              smsId: timestamp ?? DateTime.now().millisecondsSinceEpoch,
              direction: parsed.direction,
              amount: parsed.amount,
              bank: parsed.bank,
              merchantId: Value(merchantId),
              merchantRaw: Value(parsed.merchantRaw),
              accountLast4: Value(parsed.accountLast4),
              vpa: Value(parsed.vpa),
              upiRef: Value(parsed.upiRef),
              transactionDate: parsed.transactionDate ?? receivedAt,
              categoryId: Value(categoryId),
              categorySource: Value(categorySource),
              rawSms: body,
              smsSender: sender,
              smsReceivedAt: receivedAt,
            ),
          );

      onTransactionSaved?.call(id);
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<int> catchUpScan() async {
    if (_catchUpRunning) return 0;
    _catchUpRunning = true;

    try {
      final lastTxn = await (_db.select(_db.transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.smsReceivedAt)])
            ..limit(1))
          .getSingleOrNull();

      final smsReader = SmsReaderService(_engine, _resolver);
      final result = await smsReader.readAndParseAll();
      var savedCount = 0;

      for (final txn in result.parsed) {
        if (lastTxn != null && txn.rawSms.date != null) {
          if (txn.rawSms.date!.isBefore(lastTxn.smsReceivedAt)) continue;
        }

        final id = await _txnRepo.saveTransaction(txn);
        if (id != null) {
          savedCount++;
          onTransactionSaved?.call(id);
        }
      }

      return savedCount;
    } finally {
      _catchUpRunning = false;
    }
  }
}
