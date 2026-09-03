/// GS1 EAN-13 Standard Barcode Binary Encoder
/// Implements the official GS1 specification for 13-digit retail barcodes.
class GS1Ean13Encoder {
  static const List<String> _parityTable = [
    'LLLLLL', // 0
    'LLGLGG', // 1
    'LLGGLG', // 2
    'LLGGGL', // 3
    'LGLLGG', // 4
    'LGGLLG', // 5
    'LGGGLL', // 6
    'LGLGLG', // 7
    'LGLGGL', // 8
    'LGGLGL', // 9
  ];

  static const List<String> _lCode = [
    '0001101', // 0
    '0011001', // 1
    '0010011', // 2
    '0111101', // 3
    '0100011', // 4
    '0110001', // 5
    '0101111', // 6
    '0111011', // 7
    '0110111', // 8
    '0001011', // 9
  ];

  static const List<String> _gCode = [
    '0100111', // 0
    '0110011', // 1
    '0011011', // 2
    '0100001', // 3
    '0011101', // 4
    '0111001', // 5
    '0000101', // 6
    '0010001', // 7
    '0001001', // 8
    '0010111', // 9
  ];

  static const List<String> _rCode = [
    '1110010', // 0
    '1100110', // 1
    '1101100', // 2
    '1000010', // 3
    '1011100', // 4
    '1001110', // 5
    '1010000', // 6
    '1000100', // 7
    '1001000', // 8
    '1110100', // 9
  ];

  static int computeChecksum(String twelveDigits) {
    int sumOdd = 0;
    int sumEven = 0;
    for (int i = 0; i < 12; i++) {
      final d = int.tryParse(twelveDigits[i]) ?? 0;
      if (i % 2 == 0) {
        sumOdd += d;
      } else {
        sumEven += d;
      }
    }
    final total = sumOdd + (sumEven * 3);
    final mod = total % 10;
    return mod == 0 ? 0 : 10 - mod;
  }

  static String normalizeEan13(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) digits = '890123456789';
    if (digits.length < 12) {
      digits = digits.padRight(12, '0');
    } else if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }
    if (digits.length == 12) {
      digits = '$digits${computeChecksum(digits)}';
    } else if (digits.length == 13) {
      final base = digits.substring(0, 12);
      final cs = computeChecksum(base);
      digits = '$base$cs';
    }
    return digits;
  }

  static List<bool> encodeModules(String ean13) {
    final validEan = normalizeEan13(ean13);
    final firstDigit = int.parse(validEan[0]);
    final parity = _parityTable[firstDigit];

    final modules = <bool>[];

    // 1. Start Guard: 101
    modules.addAll([true, false, true]);

    // 2. Left 6 Digits
    for (int i = 0; i < 6; i++) {
      final digit = int.parse(validEan[i + 1]);
      final isL = parity[i] == 'L';
      final pattern = isL ? _lCode[digit] : _gCode[digit];
      for (int b = 0; b < pattern.length; b++) {
        modules.add(pattern[b] == '1');
      }
    }

    // 3. Center Guard: 01010
    modules.addAll([false, true, false, true, false]);

    // 4. Right 6 Digits
    for (int i = 7; i < 13; i++) {
      final digit = int.parse(validEan[i]);
      final pattern = _rCode[digit];
      for (int b = 0; b < pattern.length; b++) {
        modules.add(pattern[b] == '1');
      }
    }

    // 5. End Guard: 101
    modules.addAll([true, false, true]);

    return modules;
  }
}
