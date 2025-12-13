class AppRegex {
  // Email validation
  static bool isEmailValid(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  // Password validation (min 6 characters)
  static bool isPasswordValid(String password) {
    return password.length >= 6;
  }

  // Phone number validation (Egyptian format)
  static bool isPhoneNumberValid(String phoneNumber) {
    return RegExp(
      r'^(010|011|012|015)[0-9]{8}$',
    ).hasMatch(phoneNumber);
  }

  // Username validation (alphanumeric and underscore, 3-20 characters)
  static bool isUsernameValid(String username) {
    return RegExp(
      r'^[a-zA-Z0-9_]{3,20}$',
    ).hasMatch(username);
  }

  // Number only validation
  static bool isNumericOnly(String value) {
    return RegExp(r'^[0-9]+$').hasMatch(value);
  }

  // Decimal number validation
  static bool isDecimalNumber(String value) {
    return RegExp(r'^[0-9]+\.?[0-9]*$').hasMatch(value);
  }

  // Arabic text validation
  static bool isArabicText(String text) {
    return RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(text);
  }

  // Barcode validation (EAN-13, UPC-A, Code128, etc.)
  static bool isBarcodeValid(String barcode) {
    // Basic validation: 8-13 digits
    return RegExp(r'^[0-9]{8,13}$').hasMatch(barcode);
  }
}
