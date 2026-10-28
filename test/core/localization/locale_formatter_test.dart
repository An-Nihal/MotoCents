import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/localization/locale_formatter.dart';

void main() {
  group('LocaleFormatter', () {
    test('localizeDigits converts ASCII digits to Bengali digits', () {
      expect(LocaleFormatter.localizeDigits('12345', isBangla: true), '১২৩৪৫');
      expect(LocaleFormatter.localizeDigits('67890', isBangla: true), '৬৭৮৯০');
      expect(LocaleFormatter.localizeDigits('ABC 120.50 km', isBangla: true), 'ABC ১২০.৫০ km');
      expect(LocaleFormatter.localizeDigits('12345', isBangla: false), '12345');
    });

    test('formatNumber formats numbers with commas and locale digits', () {
      expect(LocaleFormatter.formatNumber(1250000, locale: 'en'), '1,250,000');
      expect(LocaleFormatter.formatNumber(1250000, locale: 'bn'), '১,২৫০,০০০');

      expect(LocaleFormatter.formatNumber(45.5, decimalDigits: 2, locale: 'en'), '45.50');
      expect(LocaleFormatter.formatNumber(45.5, decimalDigits: 2, locale: 'bn'), '৪৫.৫০');
    });

    test('formatCurrency attaches symbol and formats decimals', () {
      expect(
        LocaleFormatter.formatCurrency(5400.0, currencySymbol: '৳', locale: 'en'),
        '৳ 5,400.00',
      );
      expect(
        LocaleFormatter.formatCurrency(5400.0, currencySymbol: '৳', locale: 'bn'),
        '৳ ৫,৪০০.০০',
      );
    });

    test('formatDistance localizes unit and number', () {
      expect(
        LocaleFormatter.formatDistance(1250, unit: 'km', locale: 'en'),
        '1,250 km',
      );
      expect(
        LocaleFormatter.formatDistance(1250, unit: 'km', locale: 'bn'),
        '১,২৫০ কিমি',
      );
    });

    test('formatVolume localizes unit and number', () {
      expect(
        LocaleFormatter.formatVolume(45.5, unit: 'L', locale: 'en'),
        '45.50 L',
      );
      expect(
        LocaleFormatter.formatVolume(45.5, unit: 'L', locale: 'bn'),
        '৪৫.৫০ লিটার',
      );
    });

    test('formatEconomy formats mileage with units', () {
      expect(
        LocaleFormatter.formatEconomy(14.2, unit: 'km/L', locale: 'en'),
        '14.2 km/L',
      );
      expect(
        LocaleFormatter.formatEconomy(14.2, unit: 'km/L', locale: 'bn'),
        '১৪.২ কিমি/লিটার',
      );
    });

    test('formatTime formats TimeOfDay into localized string', () {
      const morningTime = TimeOfDay(hour: 9, minute: 30);
      expect(LocaleFormatter.formatTime(morningTime, locale: 'en'), '9:30 AM');
      expect(LocaleFormatter.formatTime(morningTime, locale: 'bn'), '৯:৩০ AM');

      const eveningTime = TimeOfDay(hour: 21, minute: 5);
      expect(LocaleFormatter.formatTime(eveningTime, locale: 'en'), '9:05 PM');
      expect(LocaleFormatter.formatTime(eveningTime, locale: 'bn'), '৯:০৫ PM');
    });
  });
}

