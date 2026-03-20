String formatIndianNumber(int number) {
  if (number < 0) return '-${formatIndianNumber(-number)}';
  final str = number.toString();
  if (str.length <= 3) return str;

  final last3 = str.substring(str.length - 3);
  var rest = str.substring(0, str.length - 3);
  var result = last3;

  while (rest.isNotEmpty) {
    if (rest.length > 2) {
      result = '${rest.substring(rest.length - 2)},$result';
      rest = rest.substring(0, rest.length - 2);
    } else {
      result = '$rest,$result';
      rest = '';
    }
  }

  return result;
}

String formatRupees(int paise) {
  final rupees = paise.abs() ~/ 100;
  return '₹${formatIndianNumber(rupees)}';
}

String formatRupeesWithSign(int paise, String direction) {
  final formatted = formatRupees(paise);
  if (direction == 'credit') return '+ $formatted';
  return formatted;
}
