import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/vehicles_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../shell/presentation/vehicle_selector_app_bar.dart';
import '../domain/trip_calculator_models.dart';
import '../domain/trip_cost_calculator.dart';
import 'providers/smart_providers.dart';

class TripCostCalculatorScreen extends ConsumerStatefulWidget {
  const TripCostCalculatorScreen({super.key});

  @override
  ConsumerState<TripCostCalculatorScreen> createState() =>
      _TripCostCalculatorScreenState();
}

class _TripCostCalculatorScreenState
    extends ConsumerState<TripCostCalculatorScreen> {
  final _distanceController = TextEditingController(text: '100');
  final _economyController = TextEditingController();
  final _priceController = TextEditingController();
  final _expensesController = TextEditingController(text: '0');

  bool _isRoundTrip = false;
  int _passengers = 1;
  bool _defaultsInitialized = false;

  @override
  void dispose() {
    _distanceController.dispose();
    _economyController.dispose();
    _priceController.dispose();
    _expensesController.dispose();
    super.dispose();
  }

  void _initDefaultsOnce(VehicleTripDefaults defaults) {
    if (!_defaultsInitialized) {
      _defaultsInitialized = true;
      _economyController.text = defaults.defaultEconomy.toStringAsFixed(1);
      _priceController.text = defaults.defaultPrice.toStringAsFixed(2);
    }
  }

  void _addDistance(double add) {
    final cur = double.tryParse(_distanceController.text) ?? 0.0;
    final next = (cur + add).clamp(0.0, 99999.0);
    setState(() {
      _distanceController.text = next.toStringAsFixed(0);
    });
  }

  void _copySummary(TripCalculationResult result, String currency, String distanceUnit, String volumeUnit) {
    final text = StringBuffer();
    text.writeln('🚗 Trip Cost Estimate:');
    text.writeln('• Total Distance: ${result.totalDistance.toStringAsFixed(1)} $distanceUnit ${_isRoundTrip ? '(Round Trip)' : ''}');
    text.writeln('• Fuel Needed: ${result.fuelNeededVolume.toStringAsFixed(1)} $volumeUnit');
    text.writeln('• Estimated Fuel Cost: $currency${result.estimatedFuelCost.toStringAsFixed(2)}');
    if (result.totalTripCost != result.estimatedFuelCost) {
      text.writeln('• Total Cost: $currency${result.totalTripCost.toStringAsFixed(2)}');
    }
    if (_passengers > 1) {
      text.writeln('• Split: $currency${result.costPerPerson.toStringAsFixed(2)} per person ($_passengers passengers)');
    }
    text.writeln('• Rate: $currency${result.costPerKm.toStringAsFixed(2)} / $distanceUnit');

    Clipboard.setData(ClipboardData(text: text.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip summary copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(currentVehicleProvider);
    final settings = ref.watch(settingsProvider);
    final defaultsAsync = ref.watch(vehicleTripDefaultsProvider);

    defaultsAsync.whenData((defaults) => _initDefaultsOnce(defaults));

    final currency = settings.currencySymbol;
    final distanceUnit = vehicle?.distanceUnit ?? 'km';
    final volumeUnit = vehicle?.volumeUnit ?? 'L';
    final economyUnit = vehicle?.economyUnit ?? 'km/L';

    final distance = double.tryParse(_distanceController.text) ?? 0.0;
    final economy = double.tryParse(_economyController.text) ?? 10.0;
    final price = double.tryParse(_priceController.text) ?? 130.0;
    final expenses = double.tryParse(_expensesController.text) ?? 0.0;

    final input = TripCalculationInput(
      oneWayDistance: distance,
      isRoundTrip: _isRoundTrip,
      fuelEconomy: economy,
      economyUnit: economyUnit,
      fuelPricePerUnit: price,
      passengers: _passengers,
      additionalExpenses: expenses,
      tankCapacity: vehicle?.tankCapacity,
    );

    final result = TripCostCalculator.calculate(input);

    return Scaffold(
      appBar: const VehicleAppBar(
        title: 'Trip Cost Calculator',
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Live Result Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryAmber.withValues(alpha: 0.18),
                  AppColors.secondaryTeal.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryAmber.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ESTIMATED TRIP COST',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 20),
                      tooltip: 'Copy trip estimate',
                      onPressed: () => _copySummary(result, currency, distanceUnit, volumeUnit),
                    ),
                  ],
                ),
                Text(
                  '$currency${result.totalTripCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_passengers > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    '≈ $currency${result.costPerPerson.toStringAsFixed(2)} per person ($_passengers passengers)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildResultMetric(
                      'Distance',
                      '${result.totalDistance.toStringAsFixed(0)} $distanceUnit',
                      subtitle: _isRoundTrip ? 'Round Trip' : 'One Way',
                    ),
                    _buildResultMetric(
                      'Fuel Needed',
                      '${result.fuelNeededVolume.toStringAsFixed(1)} $volumeUnit',
                      subtitle: '$currency${result.estimatedFuelCost.toStringAsFixed(0)}',
                    ),
                    _buildResultMetric(
                      'Cost Rate',
                      '$currency${result.costPerKm.toStringAsFixed(1)}/$distanceUnit',
                      subtitle: 'Efficiency',
                    ),
                  ],
                ),
                if (result.tankPercentageUsed != null && result.tankPercentageUsed! > 0) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (result.tankPercentageUsed! / 100.0).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        result.tankPercentageUsed! > 100.0 ? Colors.redAccent : AppColors.primaryAmber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Requires ${result.tankPercentageUsed!.toStringAsFixed(0)}% of your ${vehicle!.tankCapacity!.toStringAsFixed(0)} $volumeUnit tank'
                    '${result.fullTanksCount > 1 ? ' (approx. ${result.fullTanksCount} full tanks)' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Distance Input Section
          Text(
            'Trip Distance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Distance ($distanceUnit)',
              prefixIcon: const Icon(Icons.route_rounded),
              suffixText: distanceUnit,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),

          // Quick distance buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('+25 $distanceUnit', () => _addDistance(25)),
                _buildQuickChip('+50 $distanceUnit', () => _addDistance(50)),
                _buildQuickChip('+100 $distanceUnit', () => _addDistance(100)),
                _buildQuickChip('+250 $distanceUnit', () => _addDistance(250)),
                _buildQuickChip('Clear', () {
                  setState(() => _distanceController.text = '0');
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Round Trip Switch Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: SwitchListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: const Text('Round Trip (2x distance)', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _isRoundTrip
                    ? 'Total distance: ${(distance * 2).toStringAsFixed(0)} $distanceUnit'
                    : 'One-way travel only',
                style: const TextStyle(fontSize: 12),
              ),
              value: _isRoundTrip,
              activeThumbColor: AppColors.primaryAmber,
              onChanged: (val) => setState(() => _isRoundTrip = val),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Vehicle Parameters (Economy & Price)
          Text(
            'Vehicle Performance & Pricing',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _economyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Fuel Economy ($economyUnit)',
                    prefixIcon: const Icon(Icons.speed_rounded),
                    suffixText: economyUnit,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Fuel Price',
                    prefixIcon: const Icon(Icons.local_gas_station_rounded),
                    suffixText: '$currency/$volumeUnit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Carpool & Extra Expenses
          Text(
            'Carpool & Extra Expenses',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Passenger Stepper Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Passengers', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            '$_passengers ${_passengers == 1 ? 'person' : 'people'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: _passengers > 1
                                ? () => setState(() => _passengers--)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: _passengers < 10
                                ? () => setState(() => _passengers++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Additional Expenses (Tolls, Parking)
              Expanded(
                child: TextFormField(
                  controller: _expensesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Tolls / Parking',
                    prefixIcon: const Icon(Icons.toll_rounded),
                    suffixText: currency,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultMetric(String title, String mainValue, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          mainValue,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
