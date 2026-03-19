import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/services/sms_parser/template_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TemplateEngine engine;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = TemplateEngine(db);

    await db.into(db.templates).insert(TemplatesCompanion.insert(
      senderKey: 'HDFCBK',
      bankName: 'HDFC',
      direction: 'debit',
      pattern: 'Sent Rs.{amount}\nFrom HDFC Bank A/C *{last4}\nTo {merchant}\nOn {date}\nRef {upi_ref}',
      source: 'test',
    ));

    await db.into(db.templates).insert(TemplatesCompanion.insert(
      senderKey: 'HDFCBK',
      bankName: 'HDFC',
      direction: 'credit',
      pattern: 'Credit Alert!\nRs.{amount} credited to HDFC Bank A/c XX{last4} on {date} from VPA {vpa} (UPI {upi_ref})',
      source: 'test',
    ));

    await db.into(db.templates).insert(TemplatesCompanion.insert(
      senderKey: 'UNIONB',
      bankName: 'Union Bank',
      direction: 'debit',
      pattern: 'A/c *{last4} Debited for Rs:{amount} on {date} by Mob Bk ref no {upi_ref} Avl Bal Rs',
      source: 'test',
    ));
  });

  tearDown(() async {
    await db.close();
  });

  test('full pipeline - HDFC UPI debit', () async {
    final result = await engine.parseSms(
      'JX-HDFCBK-S',
      'Sent Rs.14.00\nFrom HDFC Bank A/C *4273\nTo RADHA DEVI\nOn 06/03/26\nRef 119586517898\nNot You?\nCall 18002586161/SMS BLOCK UPI to 7308080808\n',
    );

    expect(result, isNotNull);
    expect(result!.direction, 'debit');
    expect(result.amount, 1400);
    expect(result.bank, 'HDFC');
    expect(result.accountLast4, '4273');
    expect(result.merchantRaw, 'RADHA DEVI');
    expect(result.upiRef, '119586517898');
    expect(result.transactionDate, DateTime(2026, 3, 6));
  });

  test('full pipeline - HDFC UPI credit', () async {
    final result = await engine.parseSms(
      'JX-HDFCBK-S',
      'Credit Alert!\nRs.71.00 credited to HDFC Bank A/c XX4273 on 06-03-26 from VPA eraparmar00@okhdfcbank (UPI 119609013791)\n',
    );

    expect(result, isNotNull);
    expect(result!.direction, 'credit');
    expect(result.amount, 7100);
    expect(result.bank, 'HDFC');
    expect(result.accountLast4, '4273');
    expect(result.vpa, 'eraparmar00@okhdfcbank');
    expect(result.upiRef, '119609013791');
    expect(result.transactionDate, DateTime(2026, 3, 6));
  });

  test('full pipeline - Union Bank debit', () async {
    final result = await engine.parseSms(
      'AD-UNIONB-S',
      'A/c *7028 Debited for Rs:1700.00 on 07-03-2026 17:37:36 by Mob Bk ref no 119650728051 Avl Bal Rs:6891.75.If not you, Call 1800222243 -Union Bank of India',
    );

    expect(result, isNotNull);
    expect(result!.direction, 'debit');
    expect(result.amount, 170000);
    expect(result.bank, 'Union Bank');
    expect(result.accountLast4, '7028');
    expect(result.merchantRaw, isNull);
    expect(result.upiRef, '119650728051');
  });

  test('returns null for unknown sender', () async {
    final result = await engine.parseSms(
      'JX-LEVISL-P',
      'Flat Rs.999 off on women\'s apparel worth Rs.6999.',
    );

    expect(result, isNull);
  });

  test('returns null for non-matching body from known sender', () async {
    final result = await engine.parseSms(
      'JM-HDFCBK-S',
      'HDFC Bank Customer, some random promotional message here.',
    );

    expect(result, isNull);
  });
}
