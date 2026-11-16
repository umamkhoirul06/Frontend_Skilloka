/// Algoritma Luhn (Modulo 10) & Card Validator untuk Transaksi Pembayaran Skilloka
/// Digunakan untuk validasi kartu debit/kredit secara akurat sebelum diproses ke gateway
class LuhnValidator {
  const LuhnValidator._();

  /// Memeriksa apakah nomor kartu valid menurut Algoritma Luhn (Mod 10 Checksum)
  static bool isValid(String? rawCardNumber) {
    if (rawCardNumber == null) return false;
    final digits = rawCardNumber.replaceAll(RegExp(r'\D'), '');

    // Standar nomor kartu kredit/debit umumnya memiliki panjang 13 hingga 19 digit
    if (digits.length < 13 || digits.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;

    // Iterasi dari digit terakhir (kanan ke kiri)
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Alias untuk isValid
  static bool validate(String? rawCardNumber) => isValid(rawCardNumber);

  /// Memeriksa apakah input berupa kandidat nomor kartu (13-19 digit)
  static bool isCardIdentifier(String? input) {
    if (input == null) return false;
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 13 && digits.length <= 19;
  }

  /// Mendeteksi jenis/brand kartu berdasarkan nomor awal (IIN / BIN)
  static String getCardBrand(String? rawCardNumber) {
    if (rawCardNumber == null) return 'Unknown';
    final digits = rawCardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Unknown';

    if (digits.startsWith('4')) {
      return 'Visa';
    } else if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) {
      return 'Mastercard';
    } else if (RegExp(r'^3[47]').hasMatch(digits)) {
      return 'American Express';
    } else if (RegExp(r'^(352[89]|35[3-8][0-9])').hasMatch(digits)) {
      return 'JCB';
    } else if (RegExp(r'^(6011|65|64[4-9])').hasMatch(digits)) {
      return 'Discover';
    } else if (digits.startsWith('62')) {
      return 'UnionPay';
    }
    return 'Debit/Kredit';
  }

  /// Format nomor kartu dengan spasi setiap 4 digit (misal: 4532 1234 5678 9010)
  static String formatCardNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Validasi bulan dan tahun kedaluwarsa (format MM/YY)
  static bool isExpiryValid(String? expiry) {
    if (expiry == null || !expiry.contains('/')) return false;
    final parts = expiry.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0].trim());
    final year = int.tryParse(parts[1].trim());

    if (month == null || year == null || month < 1 || month > 12) {
      return false;
    }

    final now = DateTime.now();
    final currentYearTwoDigits = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYearTwoDigits) return false;
    if (year == currentYearTwoDigits && month < currentMonth) return false;
    if (year > currentYearTwoDigits + 20) return false;

    return true;
  }

  /// Validasi CVV/CVC (3 atau 4 digit)
  static bool isCvvValid(String? cvv, [String? brand]) {
    if (cvv == null) return false;
    final clean = cvv.replaceAll(RegExp(r'\D'), '');
    if (brand == 'American Express') {
      return clean.length == 4;
    }
    return clean.length == 3 || clean.length == 4;
  }
}
