import 'package:flutter/services.dart';

/// Custom TextInputFormatter to convert Arabic numerals to Western numerals
/// and ensure only Western digits are displayed
class WesternNumeralFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert Arabic numerals (٠-٩) to Western numerals (0-9)
    String newText = _convertToWesternNumerals(newValue.text);
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  String _convertToWesternNumerals(String input) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const westernNumerals = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    
    String result = input;
    for (int i = 0; i < arabicNumerals.length; i++) {
      result = result.replaceAll(arabicNumerals[i], westernNumerals[i]);
    }
    
    return result;
  }
}

/// Helper class to get common input formatters for number fields
class NumberInputFormatters {
  /// Get formatters for integer input (whole numbers only)
  static List<TextInputFormatter> integer() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      WesternNumeralFormatter(),
    ];
  }

  /// Get formatters for decimal input (allows decimal point)
  static List<TextInputFormatter> decimal() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      WesternNumeralFormatter(),
    ];
  }

  /// Get formatters for price input (2 decimal places max)
  static List<TextInputFormatter> price() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      WesternNumeralFormatter(),
    ];
  }
}
