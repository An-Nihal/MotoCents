import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/features/ocr/domain/receipt_ocr_parser.dart';

void main() {
  group('ReceiptOcrParser Unit Tests', () {
    test('Parses standard fuel receipt with explicit labels', () {
      const receiptText = '''
PADMA OIL COMPANY LIMITED
TEJGAON FILLING STATION, DHAKA
DATE: 2026-10-15
FUEL: OCTANE-95
PUMP NO: 04

VOLUME: 25.50 LTR
RATE/LTR: 130.00
TOTAL AMOUNT: 3315.00
CASH RECEIVED: 3500.00
CHANGE: 185.00
ODO: 24500 KM
THANK YOU FOR VISITING!
''';

      final result = ReceiptOcrParser.parse(receiptText);

      expect(result.quantity, 25.50);
      expect(result.pricePerUnit, 130.00);
      expect(result.totalCost, 3315.00);
      expect(result.odometer, 24500.0);
      expect(result.stationName, contains('PADMA OIL COMPANY LIMITED'));
      expect(result.fuelType, 'octane');
      expect(result.date, DateTime(2026, 10, 15));
      expect(result.confidence, greaterThanOrEqualTo(0.8));
    });

    test('Parses receipt with Bengali digits and terms', () {
      const bengaliReceipt = '''
মেঘনা পেট্রোলিয়াম লিমিটেড
ফিলিং স্টেশন, চট্টগ্রাম
তারিখ: ১৫/১০/২০২৬
জ্বালানি: পেট্রোল

পরিমাণ: ৩০.০০ লিটার
দর: ১২৫.০০
মোট টাকা: ৩৭৫০.০০
মিটার: ১২৮০০ কিমি
''';

      final result = ReceiptOcrParser.parse(bengaliReceipt);

      expect(result.quantity, 30.00);
      expect(result.pricePerUnit, 125.00);
      expect(result.totalCost, 3750.00);
      expect(result.odometer, 12800.0);
      expect(result.stationName, contains('মেঘনা'));
      expect(result.fuelType, 'petrol');
      expect(result.date, DateTime(2026, 10, 15));
    });

    test('Extracts odometer reading from dashboard cluster photo', () {
      const odometerScreen = '''
12:45 PM
TRIP A 350.2
045210 km
AVG 14.2 km/L
''';

      final result = ReceiptOcrParser.parse(odometerScreen);

      expect(result.odometer, 45210.0);
    });

    test('Mathematical cross-reconciliation works when labels are missing', () {
      // Unlabeled numbers where 20.00 * 125.00 = 2500.00
      const noisyReceipt = '''
JAMUNA OIL STATION
INVOICE #9821
2026/09/20
20.00
125.00
2500.00
''';

      final result = ReceiptOcrParser.parse(noisyReceipt);

      expect(result.quantity, 20.00);
      expect(result.pricePerUnit, 125.00);
      expect(result.totalCost, 2500.00);
      expect(result.stationName, contains('JAMUNA OIL'));
    });

    test('2-of-3 deduction calculates missing total cost', () {
      const receipt = '''
CITY FUEL PUMP
QTY: 40.00 LTR
PRICE: 120.00
''';

      final result = ReceiptOcrParser.parse(receipt);

      expect(result.quantity, 40.00);
      expect(result.pricePerUnit, 120.00);
      expect(result.totalCost, 4800.00);
    });

    test('Handles empty and invalid text safely without crashing', () {
      final emptyResult = ReceiptOcrParser.parse('');
      expect(emptyResult.hasAnyValue, isFalse);
      expect(emptyResult.confidence, 0.0);

      final gibberishResult = ReceiptOcrParser.parse('Random non-numeric gibberish words');
      expect(gibberishResult.hasAnyValue, isFalse);
    });
  });
}
