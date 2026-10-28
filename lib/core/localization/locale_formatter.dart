import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Centralized utility for formatting numbers, currencies, dates, and units
/// according to the active app locale, including Bangla numeral conversion.
class LocaleFormatter {
  static const Map<String, String> _englishToBanglaDigits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  /// Converts any string containing ASCII digits to Bengali digits if [isBangla] is true.
  static String localizeDigits(String input, {bool isBangla = false}) {
    if (!isBangla) return input;
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      buffer.write(_englishToBanglaDigits[char] ?? char);
    }
    return buffer.toString();
  }

  /// Formats a numeric value with optional decimal digits and locale-specific digits.
  static String formatNumber(
    num value, {
    int? decimalDigits,
    String locale = 'en',
  }) {
    final isBangla = locale == 'bn';
    final numberFormat = decimalDigits != null
        ? NumberFormat.currency(
            customPattern: decimalDigits > 0 ? '#,##0.${'0' * decimalDigits}' : '#,##0',
            decimalDigits: decimalDigits,
            symbol: '',
          )
        : NumberFormat('#,##0.##');

    final formatted = numberFormat.format(value).trim();
    return localizeDigits(formatted, isBangla: isBangla);
  }

  /// Formats currency with symbol prefix/suffix according to locale.
  static String formatCurrency(
    double amount, {
    required String currencySymbol,
    String locale = 'en',
    int decimalDigits = 2,
  }) {
    final numStr = formatNumber(amount, decimalDigits: decimalDigits, locale: locale);
    return '$currencySymbol $numStr';
  }

  /// Formats distance with its unit (e.g. "1,250 km" or "১,২৫০ কিমি").
  static String formatDistance(
    double distance, {
    required String unit,
    String locale = 'en',
    int decimalDigits = 0,
  }) {
    final numStr = formatNumber(distance, decimalDigits: decimalDigits, locale: locale);
    final localizedUnit = (locale == 'bn' && unit.toLowerCase() == 'km')
        ? 'কিমি'
        : (locale == 'bn' && unit.toLowerCase() == 'mi')
            ? 'মাইল'
            : unit;
    return '$numStr $localizedUnit';
  }

  /// Formats volume with its unit (e.g. "45.00 L" or "৪৫.০০ লিটার").
  static String formatVolume(
    double volume, {
    required String unit,
    String locale = 'en',
    int decimalDigits = 2,
  }) {
    final numStr = formatNumber(volume, decimalDigits: decimalDigits, locale: locale);
    final localizedUnit = (locale == 'bn' && unit.toLowerCase() == 'l')
        ? 'লিটার'
        : (locale == 'bn' && (unit.toLowerCase() == 'gal' || unit.toLowerCase() == 'gallon'))
            ? 'গ্যালন'
            : unit;
    return '$numStr $localizedUnit';
  }

  /// Formats fuel economy with its unit (e.g. "14.2 km/L").
  static String formatEconomy(
    double economy, {
    required String unit,
    String locale = 'en',
    int decimalDigits = 1,
  }) {
    final numStr = formatNumber(economy, decimalDigits: decimalDigits, locale: locale);
    final localizedUnit = (locale == 'bn' && unit == 'km/L')
        ? 'কিমি/লিটার'
        : (locale == 'bn' && unit == 'L/100km')
            ? 'লিটার/১০০ কিমি'
            : (locale == 'bn' && unit == 'MPG')
                ? 'এমপিজি'
                : unit;
    return '$numStr $localizedUnit';
  }

  /// Formats a DateTime using locale patterns and localizes digits if Bengali.
  static String formatDate(
    DateTime date, {
    String locale = 'en',
    String pattern = 'dd MMM yyyy',
  }) {
    final isBangla = locale == 'bn';
    final formatted = DateFormat(pattern, isBangla ? 'bn' : 'en').format(date);
    return localizeDigits(formatted, isBangla: isBangla);
  }

  /// Formats a TimeOfDay into localized HH:mm AM/PM string.
  static String formatTime(
    TimeOfDay time, {
    String locale = 'en',
  }) {
    final isBangla = locale == 'bn';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final raw = '$hour:$minute $period';
    return localizeDigits(raw, isBangla: isBangla);
  }
}
