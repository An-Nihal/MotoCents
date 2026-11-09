import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/features/fuel/domain/fuel_entry_auto_calc.dart';

void main() {
  group('FuelEntryAutoCalc', () {
    test('Calculates total cost from quantity and price per unit', () {
      final total = FuelEntryAutoCalc.calculateThird(
        quantity: 35.5,
        pricePerUnit: 130.0,
        target: AutoCalcTarget.totalCost,
      );
      expect(total, 4615.0);
    });

    test('Calculates quantity from total cost and price per unit', () {
      final qty = FuelEntryAutoCalc.calculateThird(
        totalCost: 4615.0,
        pricePerUnit: 130.0,
        target: AutoCalcTarget.quantity,
      );
      expect(qty, 35.5);
    });

    test('Calculates price per unit from total cost and quantity', () {
      final price = FuelEntryAutoCalc.calculateThird(
        totalCost: 4615.0,
        quantity: 35.5,
        target: AutoCalcTarget.pricePerUnit,
      );
      expect(price, 130.0);
    });

    test('Handles zero and negative values safely', () {
      expect(
        FuelEntryAutoCalc.calculateThird(
          totalCost: 4615.0,
          pricePerUnit: 0.0,
          target: AutoCalcTarget.quantity,
        ),
        isNull,
      );
      expect(
        FuelEntryAutoCalc.calculateThird(
          totalCost: 4615.0,
          quantity: 0.0,
          target: AutoCalcTarget.pricePerUnit,
        ),
        isNull,
      );
    });

    test('Trip meter to total odometer conversion', () {
      final odo = FuelEntryAutoCalc.convertTripToOdometer(
        tripDistance: 450.5,
        previousOdometer: 15000.0,
      );
      expect(odo, 15450.5);
    });

    test('Odometer validation rejects values <= previous odometer', () {
      final valid = FuelEntryAutoCalc.validateOdometer(
        newOdometer: 15500.0,
        previousOdometer: 15000.0,
      );
      expect(valid, isNull);

      final invalidLess = FuelEntryAutoCalc.validateOdometer(
        newOdometer: 14900.0,
        previousOdometer: 15000.0,
      );
      expect(invalidLess, isNotNull);

      final invalidEqual = FuelEntryAutoCalc.validateOdometer(
        newOdometer: 15000.0,
        previousOdometer: 15000.0,
      );
      expect(invalidEqual, isNotNull);
    });

    test('Unusually large jump detection', () {
      expect(
        FuelEntryAutoCalc.isUnusuallyLargeJump(
          newOdometer: 15500.0,
          previousOdometer: 15000.0,
          threshold: 2000.0,
        ),
        isFalse,
      );

      expect(
        FuelEntryAutoCalc.isUnusuallyLargeJump(
          newOdometer: 18000.0,
          previousOdometer: 15000.0,
          threshold: 2000.0,
        ),
        isTrue,
      );
    });
  });
}
