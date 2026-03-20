import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:autotally_flutter/models/parsed_sms.dart';
import 'package:autotally_flutter/services/sms_parser/template_engine.dart';
import 'package:autotally_flutter/services/merchant_resolver/merchant_resolver.dart';

typedef SmsProgressCallback = void Function({
  required int total,
  required int processed,
  required int matched,
  required String phase,
});

class SmsReadResult {
  final List<ParsedTransaction> parsed;
  final List<SmsMessage> unmatched;
  final int totalInbox;
  final int totalFinancial;

  SmsReadResult({
    required this.parsed,
    required this.unmatched,
    required this.totalInbox,
    required this.totalFinancial,
  });
}

class ParsedTransaction {
  final ParsedSMS data;
  final SmsMessage rawSms;
  final int? merchantId;

  ParsedTransaction({required this.data, required this.rawSms, this.merchantId});
}

class SmsReaderService {
  final TemplateEngine _engine;
  final MerchantResolver _resolver;
  final SmsQuery _smsQuery;

  static final _financialPattern = RegExp(
    r'(rs\.?\s?\d|inr\s?\d|debited|credited|spent|withdrawn|deposited|transferred|upi\s|neft|imps|a/c\s|your\sa/c)',
    caseSensitive: false,
  );

  SmsReaderService(this._engine, this._resolver) : _smsQuery = SmsQuery();

  static bool _isTransactionalSender(String address) {
    final cleaned = address.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'[a-zA-Z]{2,}').hasMatch(cleaned) &&
        !RegExp(r'^\+?\d{10,}$').hasMatch(cleaned);
  }

  static bool _isFinancialSms(String body) {
    return _financialPattern.hasMatch(body);
  }

  Future<SmsReadResult> readAndParseAll({
    SmsProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      total: 0,
      processed: 0,
      matched: 0,
      phase: 'reading',
    );

    final messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    final financial = <SmsMessage>[];
    for (final sms in messages) {
      if (sms.address == null || sms.body == null) continue;
      if (!_isTransactionalSender(sms.address!)) continue;
      if (!_isFinancialSms(sms.body!)) continue;
      financial.add(sms);
    }

    onProgress?.call(
      total: financial.length,
      processed: 0,
      matched: 0,
      phase: 'filtering',
    );

    final parsed = <ParsedTransaction>[];
    final unmatched = <SmsMessage>[];

    for (int i = 0; i < financial.length; i++) {
      final sms = financial[i];

      try {
        final result = await _engine.parseSms(sms.address!, sms.body!);

        if (result != null) {
          final merchantId = await _resolver.resolve(result.merchantRaw);
          parsed.add(ParsedTransaction(
            data: result,
            rawSms: sms,
            merchantId: merchantId,
          ));
        } else {
          unmatched.add(sms);
        }
      } catch (_) {
        unmatched.add(sms);
      }

      if (onProgress != null && (i % 10 == 0 || i == financial.length - 1)) {
        onProgress(
          total: financial.length,
          processed: i + 1,
          matched: parsed.length,
          phase: 'parsing',
        );
      }
    }

    return SmsReadResult(
      parsed: parsed,
      unmatched: unmatched,
      totalInbox: messages.length,
      totalFinancial: financial.length,
    );
  }
}
