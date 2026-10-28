import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';

const _uuid = Uuid();

class DefaultSeeds {
  static const List<Map<String, dynamic>> defaultServiceTypes = [
    {
      'name': 'Engine Oil Change',
      'code': 'engine_oil',
      'defaultDistance': 3000.0,
      'defaultMonths': 3,
    },
    {
      'name': 'Oil Filter',
      'code': 'oil_filter',
      'defaultDistance': 6000.0,
      'defaultMonths': 6,
    },
    {
      'name': 'Air Filter',
      'code': 'air_filter',
      'defaultDistance': 10000.0,
      'defaultMonths': 12,
    },
    {
      'name': 'Fuel Filter',
      'code': 'fuel_filter',
      'defaultDistance': 20000.0,
      'defaultMonths': 24,
    },
    {
      'name': 'General Service',
      'code': 'general_service',
      'defaultDistance': 5000.0,
      'defaultMonths': 6,
    },
    {
      'name': 'Spark Plug',
      'code': 'spark_plug',
      'defaultDistance': 15000.0,
      'defaultMonths': 12,
    },
    {
      'name': 'Brake Pads',
      'code': 'brake_pads',
      'defaultDistance': 20000.0,
      'defaultMonths': 12,
    },
    {
      'name': 'Brake Oil',
      'code': 'brake_oil',
      'defaultDistance': 20000.0,
      'defaultMonths': 24,
    },
    {
      'name': 'Tyres',
      'code': 'tyres',
      'defaultDistance': 40000.0,
      'defaultMonths': 48,
    },
    {
      'name': 'Tyre Rotation / Alignment',
      'code': 'tyre_rotation',
      'defaultDistance': 10000.0,
      'defaultMonths': 6,
    },
    {
      'name': 'Battery',
      'code': 'battery',
      'defaultDistance': null,
      'defaultMonths': 24,
    },
    {
      'name': 'Chain & Sprocket',
      'code': 'chain_sprocket',
      'defaultDistance': 15000.0,
      'defaultMonths': 12,
    },
    {
      'name': 'Clutch',
      'code': 'clutch',
      'defaultDistance': null,
      'defaultMonths': null,
    },
    {
      'name': 'Coolant',
      'code': 'coolant',
      'defaultDistance': 20000.0,
      'defaultMonths': 24,
    },
    {
      'name': 'AC Service',
      'code': 'ac_service',
      'defaultDistance': null,
      'defaultMonths': 12,
    },
    {
      'name': 'Wash & Polish',
      'code': 'wash',
      'defaultDistance': null,
      'defaultMonths': 1,
    },
  ];

  static const List<Map<String, dynamic>> defaultExpenseCategories = [
    {'name': 'Parking', 'code': 'parking'},
    {'name': 'Toll', 'code': 'toll'},
    {'name': 'Wash', 'code': 'wash'},
    {'name': 'Traffic Fine', 'code': 'fine'},
    {'name': 'Insurance', 'code': 'insurance'},
    {'name': 'Registration & Renewal Fees', 'code': 'reg_fees'},
    {'name': 'Accessories', 'code': 'accessories'},
    {'name': 'Loan / EMI', 'code': 'loan_emi'},
    {'name': 'Other', 'code': 'other'},
  ];

  static const List<Map<String, dynamic>> defaultDocumentTypes = [
    {
      'name': 'Driving License',
      'code': 'driving_license',
      'isVehicleSpecific': false,
    },
    {
      'name': 'Registration (Blue Book)',
      'code': 'registration',
      'isVehicleSpecific': true,
    },
    {
      'name': 'Tax Token',
      'code': 'tax_token',
      'isVehicleSpecific': true,
    },
    {
      'name': 'Smart Card',
      'code': 'smart_card',
      'isVehicleSpecific': true,
    },
    {
      'name': 'Fitness Certificate',
      'code': 'fitness',
      'isVehicleSpecific': true,
    },
    {
      'name': 'Insurance',
      'code': 'insurance',
      'isVehicleSpecific': true,
    },
    {
      'name': 'Route Permit',
      'code': 'route_permit',
      'isVehicleSpecific': true,
    },
    {
      'name': 'National ID (NID)',
      'code': 'nid',
      'isVehicleSpecific': false,
    },
    {
      'name': 'Other / Custom',
      'code': 'custom',
      'isVehicleSpecific': true,
    },
  ];

  static const Map<String, String> defaultSettings = {
    'language': 'en',
    'currency': 'BDT',
    'currency_symbol': '৳',
    'distance_unit': 'km',
    'volume_unit': 'L',
    'economy_unit': 'km/L',
    'theme_mode': 'system',
    'selected_vehicle_id': '',
  };

  static Future<void> seedDatabase(AppDatabase db) async {
    final now = DateTime.now();

    // 1. Service Types
    for (final st in defaultServiceTypes) {
      await db.into(db.serviceTypes).insert(
            ServiceTypesCompanion.insert(
              id: _uuid.v4(),
              name: st['name'] as String,
              code: Value(st['code'] as String?),
              defaultDistanceInterval: Value(st['defaultDistance'] as double?),
              defaultMonthInterval: Value(st['defaultMonths'] as int?),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }

    // 2. Expense Categories
    for (final ec in defaultExpenseCategories) {
      await db.into(db.expenseCategories).insert(
            ExpenseCategoriesCompanion.insert(
              id: _uuid.v4(),
              name: ec['name'] as String,
              code: Value(ec['code'] as String?),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }

    // 3. Document Types
    for (final dt in defaultDocumentTypes) {
      await db.into(db.documentTypes).insert(
            DocumentTypesCompanion.insert(
              id: _uuid.v4(),
              name: dt['name'] as String,
              code: Value(dt['code'] as String?),
              isVehicleSpecific: Value(dt['isVehicleSpecific'] as bool),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }

    // 4. Default Settings
    for (final entry in defaultSettings.entries) {
      await db.into(db.settings).insert(
            SettingsCompanion.insert(
              id: entry.key,
              value: entry.value,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }
}
