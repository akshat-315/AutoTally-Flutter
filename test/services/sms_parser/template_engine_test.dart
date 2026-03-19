import 'package:flutter_test/flutter_test.dart';
import 'package:autotally_flutter/services/sms_parser/template_engine.dart';

void main() {
  group('compileTemplate', () {
    test('HDFC UPI debit - real SMS from user phone', () {
      final pattern = 'Sent Rs.{amount}\nFrom HDFC Bank A/C *{last4}\nTo {merchant}\nOn {date}\nRef {upi_ref}';
      final regex = compileTemplate(pattern);

      final sms = 'Sent Rs.14.00\n'
          'From HDFC Bank A/C *4273\n'
          'To RADHA DEVI\n'
          'On 06/03/26\n'
          'Ref 119586517898\n'
          'Not You?\n'
          'Call 18002586161/SMS BLOCK UPI to 7308080808\n';

      final match = regex.firstMatch(sms);
      expect(match, isNotNull);
      expect(match!.namedGroup('amount'), '14.00');
      expect(match.namedGroup('last4'), '4273');
      expect(match.namedGroup('merchant'), 'RADHA DEVI');
      expect(match.namedGroup('date'), '06/03/26');
      expect(match.namedGroup('upi_ref'), '119586517898');
    });

    test('HDFC UPI credit - real SMS from user phone', () {
      final pattern = 'Credit Alert!\nRs.{amount} credited to HDFC Bank A/c XX{last4} on {date} from VPA {vpa} (UPI {upi_ref})';
      final regex = compileTemplate(pattern);

      final sms = 'Credit Alert!\n'
          'Rs.71.00 credited to HDFC Bank A/c XX4273 on 06-03-26 '
          'from VPA eraparmar00@okhdfcbank (UPI 119609013791)\n';

      final match = regex.firstMatch(sms);
      expect(match, isNotNull);
      expect(match!.namedGroup('amount'), '71.00');
      expect(match.namedGroup('last4'), '4273');
      expect(match.namedGroup('date'), '06-03-26');
      expect(match.namedGroup('vpa'), 'eraparmar00@okhdfcbank');
      expect(match.namedGroup('upi_ref'), '119609013791');
    });

    test('HDFC EMI payment - real SMS from user phone', () {
      final pattern = 'HDFC Bank Customer, Payment of Rs {amount} was credited to your Debit Card EMI Loan {last4} on {date}';
      final regex = compileTemplate(pattern);

      final sms = 'HDFC Bank Customer, Payment of Rs 1047 was credited to your Debit Card EMI Loan 2593 on 05/MAR/2026';

      final match = regex.firstMatch(sms);
      expect(match, isNotNull);
      expect(match!.namedGroup('amount'), '1047');
      expect(match.namedGroup('last4'), '2593');
      expect(match.namedGroup('date'), '05/MAR/2026');
    });

    test('Union Bank debit - real SMS from user', () {
      final pattern = 'A/c *{last4} Debited for Rs:{amount} on {date} by Mob Bk ref no {upi_ref} Avl Bal Rs';
      final regex = compileTemplate(pattern);

      final sms = 'A/c *7028 Debited for Rs:1700.00 on 07-03-2026 17:37:36 by Mob Bk ref no 119650728051 Avl Bal Rs:6891.75.If not you, Call 1800222243 -Union Bank of India';

      final match = regex.firstMatch(sms);
      expect(match, isNotNull);
      expect(match!.namedGroup('amount'), '1700.00');
      expect(match.namedGroup('last4'), '7028');
      expect(match.namedGroup('upi_ref'), '119650728051');
    });

    test('does not match non-financial SMS', () {
      final pattern = 'Sent Rs.{amount}\nFrom HDFC Bank A/C *{last4}\nTo {merchant}\nOn {date}\nRef {upi_ref}';
      final regex = compileTemplate(pattern);

      final sms = 'Flat Rs.999 off on women\'s apparel worth Rs.6999. Celebrate Women\'s Day with Levi\'s.';

      final match = regex.firstMatch(sms);
      expect(match, isNull);
    });

    test('handles comma-separated amounts', () {
      final pattern = 'Rs.{amount} debited from A/c XX{last4}';
      final regex = compileTemplate(pattern);

      final sms = 'Rs.1,50,000.50 debited from A/c XX1234';

      final match = regex.firstMatch(sms);
      expect(match, isNotNull);
      expect(match!.namedGroup('amount'), '1,50,000.50');
    });

    test('case insensitive matching', () {
      final pattern = 'Sent Rs.{amount}\nFrom HDFC Bank A/C *{last4}';
      final regex = compileTemplate(pattern);

      final sms = 'sent rs.500.00\nfrom hdfc bank a/c *1234';

      final match = regex.firstMatch(sms);
      expect(match, isNotNull);
      expect(match!.namedGroup('amount'), '500.00');
    });
  });

  group('amount parsing', () {
    test('simple amount converts to paise', () {
      final pattern = 'Rs.{amount} debited';
      final regex = compileTemplate(pattern);
      final match = regex.firstMatch('Rs.499.50 debited')!;
      final amountStr = match.namedGroup('amount')!;
      final paise = (double.parse(amountStr.replaceAll(',', '')) * 100).round();
      expect(paise, 49950);
    });

    test('comma-separated amount converts to paise', () {
      final amountStr = '1,700.00';
      final paise = (double.parse(amountStr.replaceAll(',', '')) * 100).round();
      expect(paise, 170000);
    });

    test('whole number amount converts to paise', () {
      final amountStr = '1047';
      final paise = (double.parse(amountStr.replaceAll(',', '')) * 100).round();
      expect(paise, 104700);
    });
  });
}
