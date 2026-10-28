import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/features/statistics/domain/statistics_calculator.dart';
import 'package:fuel_and_service_log/features/statistics/domain/statistics_models.dart';

void main() {
  group('StatisticsCalculator Unit Tests', () {
    final now = DateTime(2026, 10, 28, 12, 0);

    final mockVehicle = VehicleData(
      id: 'v-1',
      name: 'Corolla',
      vehicleType: 'car',
      plateNumber: 'DHK-1122',
      fuelType: 'octane',
      initialOdometer: 10000.0,
      distanceUnit: 'km',
      volumeUnit: 'L',
      economyUnit: 'km/L',
      isArchived: false,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final mockCategories = [
      ExpenseCategoryData(
        id: 'cat-parking',
        name: 'Parking',
        code: 'parking',
        isCustom: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      ExpenseCategoryData(
        id: 'cat-toll',
        name: 'Toll',
        code: 'toll',
        isCustom: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];

    test('Calculates TCO, percentages, and cost per distance correctly', () {
      final fuelEntries = [
        FuelEntryData(
          id: 'f-1',
          vehicleId: 'v-1',
          entryDateTime: DateTime(2026, 10, 1),
          odometer: 10000.0,
          quantity: 40.0,
          pricePerUnit: 130.0,
          totalCost: 5200.0,
          fuelType: 'octane',
          isFullTank: true,
          isMissedPrevious: false,
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        ),
        FuelEntryData(
          id: 'f-2',
          vehicleId: 'v-1',
          entryDateTime: DateTime(2026, 10, 15),
          odometer: 10500.0,
          quantity: 45.0,
          pricePerUnit: 130.0,
          totalCost: 5850.0,
          fuelType: 'octane',
          isFullTank: true,
          isMissedPrevious: false,
          createdAt: DateTime(2026, 10, 15),
          updatedAt: DateTime(2026, 10, 15),
        ),
      ];

      final serviceEntries = [
        ServiceEntryData(
          id: 's-1',
          vehicleId: 'v-1',
          serviceDate: DateTime(2026, 10, 10),
          odometer: 10300.0,
          laborCost: 1000.0,
          totalCost: 4000.0,
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 10),
        ),
      ];

      final expenses = [
        ExpenseData(
          id: 'e-1',
          vehicleId: 'v-1',
          categoryId: 'cat-parking',
          date: DateTime(2026, 10, 5),
          amount: 500.0,
          createdAt: DateTime(2026, 10, 5),
          updatedAt: DateTime(2026, 10, 5),
        ),
        ExpenseData(
          id: 'e-2',
          vehicleId: 'v-1',
          categoryId: 'cat-toll',
          date: DateTime(2026, 10, 12),
          amount: 450.0,
          createdAt: DateTime(2026, 10, 12),
          updatedAt: DateTime(2026, 10, 12),
        ),
      ];

      final stats = StatisticsCalculator.calculate(
        fuelEntries: fuelEntries,
        serviceEntries: serviceEntries,
        expenses: expenses,
        expenseCategories: mockCategories,
        vehicle: mockVehicle,
        period: StatisticsPeriod.sixMonths,
        referenceDate: now,
      );

      // Total Fuel = 5200 + 5850 = 11050
      // Total Service = 4000
      // Total Other = 500 + 450 = 950
      // TCO = 11050 + 4000 + 950 = 16000
      expect(stats.totalFuelSpend, equals(11050.0));
      expect(stats.totalServiceSpend, equals(4000.0));
      expect(stats.totalOtherSpend, equals(950.0));
      expect(stats.totalSpend, equals(16000.0));

      // TCO breakdown
      expect(stats.tcoBreakdown.length, equals(3));
      final fuelItem = stats.tcoBreakdown.firstWhere((i) => i.label == 'Fuel');
      expect(fuelItem.amount, equals(11050.0));
      expect(fuelItem.percentage, closeTo((11050 / 16000) * 100, 0.01));

      // Category breakdown
      expect(stats.expenseCategoryBreakdown.length, equals(2));
      expect(stats.expenseCategoryBreakdown[0].label, equals('Parking'));
      expect(stats.expenseCategoryBreakdown[0].amount, equals(500.0));
      expect(stats.expenseCategoryBreakdown[1].label, equals('Toll'));
      expect(stats.expenseCategoryBreakdown[1].amount, equals(450.0));

      // Distance: 10500 - 10000 = 500 km
      expect(stats.totalDistance, equals(500.0));
      // Cost per km: 16000 / 500 = 32.0 BDT/km
      expect(stats.costPerDistance, equals(32.0));

      // Mileage trend: 2nd entry (10500 - 10000) / 45L = 500 / 45 = 11.11 km/L
      expect(stats.mileageTrend.length, equals(1));
      expect(stats.mileageTrend.first.mileage, closeTo(11.11, 0.01));
      expect(stats.avgMileage, closeTo(11.11, 0.01));
    });
  });
}
