import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:autotally_flutter/models/parsed_sms.dart';
import 'package:autotally_flutter/services/sms_parser/template_engine.dart';
import 'package:autotally_flutter/services/merchant_resolver/merchant_resolver.dart';

class SmsReadResult {
  final List<ParsedTransaction> parsed;
  final List<SmsMessage> unmatched;

  SmsReadResult({required this.parsed, required this.unmatched});
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

  SmsReaderService(this._engine, this._resolver) : _smsQuery = SmsQuery();

  Future<SmsReadResult> readAndParseAll() async {
    final messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    final parsed = <ParsedTransaction>[];
    final unmatched = <SmsMessage>[];

    for (final sms in messages) {
      if (sms.address == null || sms.body == null) continue;

      final result = await _engine.parseSms(sms.address!, sms.body!);
      if (result != null) {
        final merchantId = await _resolver.resolve(result.merchantRaw);
        parsed.add(ParsedTransaction(data: result, rawSms: sms, merchantId: merchantId));
      }
    }

    return SmsReadResult(parsed: parsed, unmatched: unmatched);
  }
}
