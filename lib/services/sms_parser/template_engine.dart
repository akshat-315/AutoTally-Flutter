import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/models/parsed_sms.dart';

const _placeholderPatterns = {
  'amount': r'(?<amount>[\d,]+(?:\.\d{1,2})?)',
  'merchant': r'(?<merchant>.+?)',
  'date': r'(?<date>[\w/\-\.]+(?:\s[\d:]+)?(?:\s\w+\s\d{4})?)',
  'vpa': r'(?<vpa>\S+)',
  'upi_ref': r'(?<upi_ref>\w+)',
  'last4': r'(?<last4>\w+)',
};

RegExp compileTemplate(String template) {
  var normalized = template.split(RegExp(r'\s+')).join(' ');
  var escaped = RegExp.escape(normalized);
  for (final entry in _placeholderPatterns.entries) {
    final escapedPlaceholder = RegExp.escape('{${entry.key}}');
    escaped = escaped.replaceAll(escapedPlaceholder, entry.value);
  }
  escaped = escaped.replaceAll(' ', r'\s+');
  return RegExp(escaped, dotAll: true, caseSensitive: false);
}

int _parseAmount(String amountStr) {
  final cleaned = amountStr.replaceAll(',', '');
  final rupees = double.parse(cleaned);
  return (rupees * 100).round();
}

DateTime? _parseDate(String dateStr) {
  final stripped = dateStr.trim();
  final formats = [
    _tryParseDDMMYY,
    _tryParseDDMMYYYY,
    _tryParseDDMMMYY,
    _tryParseDDMMMYYYY,
  ];
  for (final parser in formats) {
    final result = parser(stripped);
    if (result != null) return result;
  }
  return null;
}

DateTime? _tryParseDDMMYY(String s) {
  final match = RegExp(r'^(\d{2})[/\-\.](\d{2})[/\-\.](\d{2})$').firstMatch(s);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = 2000 + int.parse(match.group(3)!);
  return DateTime(year, month, day);
}

DateTime? _tryParseDDMMYYYY(String s) {
  final match = RegExp(r'^(\d{2})[/\-\.](\d{2})[/\-\.](\d{4})$').firstMatch(s);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  return DateTime(year, month, day);
}

final _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

DateTime? _tryParseDDMMMYY(String s) {
  final match = RegExp(r'^(\d{2})[/\-\.](\w{3})[/\-\.](\d{2})$', caseSensitive: false).firstMatch(s);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = _months[match.group(2)!.toLowerCase()];
  if (month == null) return null;
  final year = 2000 + int.parse(match.group(3)!);
  return DateTime(year, month, day);
}

DateTime? _tryParseDDMMMYYYY(String s) {
  final match = RegExp(r'^(\d{2})[/\-\. ](\w{3})[/\-\. ](\d{4})$', caseSensitive: false).firstMatch(s);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = _months[match.group(2)!.toLowerCase()];
  if (month == null) return null;
  final year = int.parse(match.group(3)!);
  return DateTime(year, month, day);
}

class TemplateEngine {
  final AppDatabase _db;

  TemplateEngine(this._db);

  Future<List<Template>> _getTemplatesForSender(String sender) async {
    final senderUpper = sender.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    final allTemplates = await (_db.select(_db.templates)
          ..where((t) => t.isActive.equals(true)))
        .get();
    return allTemplates
        .where((t) {
          final key = t.senderKey.toUpperCase();
          return senderUpper.contains(key) || senderUpper.endsWith(key);
        })
        .toList();
  }

  Future<ParsedSMS?> parseSms(String sender, String body) async {
    final templates = await _getTemplatesForSender(sender);
    if (templates.isEmpty) return null;

    for (final template in templates) {
      final regex = compileTemplate(template.pattern);
      final match = regex.firstMatch(body);
      if (match == null) continue;

      final amountStr = match.namedGroup('amount');
      if (amountStr == null) continue;

      DateTime? txDate;
      final dateStr = _tryNamedGroup(match, 'date');
      if (dateStr != null) {
        txDate = _parseDate(dateStr);
      }

      final vpa = _tryNamedGroup(match, 'vpa');
      final merchantRaw = _tryNamedGroup(match, 'merchant') ?? vpa;

      return ParsedSMS(
        direction: template.direction,
        amount: _parseAmount(amountStr),
        bank: template.bankName,
        accountLast4: _tryNamedGroup(match, 'last4'),
        merchantRaw: merchantRaw,
        vpa: vpa,
        upiRef: _tryNamedGroup(match, 'upi_ref'),
        transactionDate: txDate,
      );
    }

    return null;
  }

  String? _tryNamedGroup(RegExpMatch match, String name) {
    try {
      return match.namedGroup(name);
    } catch (_) {
      return null;
    }
  }
}
