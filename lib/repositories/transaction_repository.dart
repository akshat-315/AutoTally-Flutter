import 'package:drift/drift.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/services/sms_reader/sms_reader_service.dart';

class TransactionRepository {
  final AppDatabase _db;

  TransactionRepository(this._db);

  Future<int?> saveTransaction(ParsedTransaction tx) async {
    final smsId = tx.rawSms.id;
    if (smsId == null) return null;

    final exists = await (_db.select(_db.transactions)
          ..where((t) => t.smsId.equals(smsId)))
        .getSingleOrNull();
    if (exists != null) return null;

    final body = tx.rawSms.body ?? '';
    final sender = tx.rawSms.address ?? '';
    if (body.isNotEmpty) {
      final contentDupe = await (_db.select(_db.transactions)
            ..where((t) => t.rawSms.equals(body))
            ..where((t) => t.smsSender.equals(sender)))
          .getSingleOrNull();
      if (contentDupe != null) return null;
    }

    int? categoryId;
    String? categorySource;
    if (tx.merchantId != null) {
      final merchant = await (_db.select(_db.merchants)
            ..where((m) => m.id.equals(tx.merchantId!)))
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

    final id = await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            smsId: smsId,
            direction: tx.data.direction,
            amount: tx.data.amount,
            bank: tx.data.bank,
            merchantId: Value(tx.merchantId),
            merchantRaw: Value(tx.data.merchantRaw),
            accountLast4: Value(tx.data.accountLast4),
            vpa: Value(tx.data.vpa),
            upiRef: Value(tx.data.upiRef),
            transactionDate: tx.data.transactionDate ?? DateTime.now(),
            categoryId: Value(categoryId),
            categorySource: Value(categorySource),
            rawSms: tx.rawSms.body ?? '',
            smsSender: tx.rawSms.address ?? '',
            smsReceivedAt: tx.rawSms.date ?? DateTime.now(),
          ),
        );

    return id;
  }

  Future<int> saveBatch(List<ParsedTransaction> txns) async {
    var count = 0;
    for (final tx in txns) {
      final id = await saveTransaction(tx);
      if (id != null) count++;
    }
    return count;
  }
}
