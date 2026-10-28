import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../shell/presentation/vehicle_selector_app_bar.dart';
import '../domain/statistics_models.dart';
import 'providers/statistics_providers.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final selectedPeriod = ref.watch(statisticsPeriodProvider);
    final summaryAsync = ref.watch(statisticsSummaryProvider);

    return Scaffold(
      appBar: const VehicleAppBar(
        title: 'Statistics & Charts',
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error computing statistics: $err')),
        data: (stats) {
          final hasData = stats.totalSpend > 0 || stats.mileageTrend.isNotEmpty;

          return CustomScrollView(
            slivers: [
              // Period Selector Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: StatisticsPeriod.values.map((p) {
                        final isSelected = selectedPeriod == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(p.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                ref.read(statisticsPeriodProvider.notifier).setPeriod(p);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              if (!hasData)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else ...[
                // Top 4 KPI Metrics Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildMetricTile(
                              title: 'Total Spend (TCO)',
                              value:
                                  '${settings.currencySymbol} ${stats.totalSpend.toStringAsFixed(0)}',
                              icon: Icons.account_balance_wallet_rounded,
                              color: AppColors.primaryAmber,
                            ),
                            const SizedBox(width: 12),
                            _buildMetricTile(
                              title: 'Cost per ${settings.distanceUnit}',
                              value: stats.costPerDistance > 0
                                  ? '${settings.currencySymbol} ${stats.costPerDistance.toStringAsFixed(2)}'
                                  : 'N/A',
                              icon: Icons.alt_route_rounded,
                              color: AppColors.secondaryTeal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMetricTile(
                              title: 'Cost per Day',
                              value: stats.costPerDay > 0
                                  ? '${settings.currencySymbol} ${stats.costPerDay.toStringAsFixed(1)}'
                                  : 'N/A',
                              icon: Icons.today_rounded,
                              color: Colors.purple.shade600,
                            ),
                            const SizedBox(width: 12),
                            _buildMetricTile(
                              title: 'Average Economy',
                              value: stats.avgMileage > 0
                                  ? '${stats.avgMileage.toStringAsFixed(1)} ${settings.economyUnit}'
                                  : 'N/A',
                              icon: Icons.speed_rounded,
                              color: Colors.blue.shade600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Chart 1: Total Cost Breakdown (Donut Chart)
                if (stats.tcoBreakdown.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildDonutChartCard(stats),
                  ),

                // Chart 2: Monthly Spending Trend (Bar Chart)
                if (stats.monthlyTrends.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildMonthlyBarChartCard(stats),
                  ),

                // Chart 3: Fuel Economy Trend (Line Chart)
                if (stats.mileageTrend.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildMileageLineChartCard(stats),
                  ),

                // Chart 4: Other Expenses by Category (Horizontal Bars)
                if (stats.expenseCategoryBreakdown.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildCategoryBreakdownCard(stats),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChartCard(VehicleStatisticsSummary stats) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cost Breakdown (TCO)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Distribution across Fuel, Service, and Other Expenses',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex =
                              pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 46,
                    sections: stats.tcoBreakdown.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final isTouched = idx == _touchedPieIndex;
                      final radius = isTouched ? 48.0 : 40.0;

                      return PieChartSectionData(
                        color: item.color,
                        value: item.amount,
                        title: '${item.percentage.toStringAsFixed(0)}%',
                        radius: radius,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: stats.tcoBreakdown.map((item) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.label}: ',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${settings.currencySymbol} ${item.amount.toStringAsFixed(0)} (${item.percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChartCard(VehicleStatisticsSummary stats) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final trends = stats.monthlyTrends;

    double maxMonthSpend = 0.0;
    for (final m in trends) {
      if (m.totalCost > maxMonthSpend) maxMonthSpend = m.totalCost;
    }
    if (maxMonthSpend == 0.0) maxMonthSpend = 1000.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Running Cost',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total spending trend per calendar month',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxMonthSpend * 1.15,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final m = trends[group.x.toInt()];
                          return BarTooltipItem(
                            '${m.monthLabel}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: 'Fuel: ${settings.currencySymbol} ${m.fuelCost.toStringAsFixed(0)}\n',
                                style: const TextStyle(color: AppColors.primaryAmber, fontSize: 11),
                              ),
                              TextSpan(
                                text: 'Service: ${settings.currencySymbol} ${m.serviceCost.toStringAsFixed(0)}\n',
                                style: const TextStyle(color: AppColors.secondaryTeal, fontSize: 11),
                              ),
                              TextSpan(
                                text: 'Other: ${settings.currencySymbol} ${m.otherExpensesCost.toStringAsFixed(0)}\n',
                                style: TextStyle(color: Colors.purple.shade300, fontSize: 11),
                              ),
                              TextSpan(
                                text: 'Total: ${settings.currencySymbol} ${m.totalCost.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= trends.length) return const SizedBox.shrink();
                            final m = trends[idx];
                            // Show abbreviated 3-letter month
                            final parts = m.monthLabel.split(' ');
                            final label = parts.isNotEmpty ? parts.first : m.monthLabel;

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: trends.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final m = entry.value;

                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: m.totalCost,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                            rodStackItems: [
                              BarChartRodStackItem(0, m.fuelCost, AppColors.primaryAmber),
                              BarChartRodStackItem(
                                m.fuelCost,
                                m.fuelCost + m.serviceCost,
                                AppColors.secondaryTeal,
                              ),
                              BarChartRodStackItem(
                                m.fuelCost + m.serviceCost,
                                m.totalCost,
                                Colors.purple.shade400,
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Segment legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDot(AppColors.primaryAmber, 'Fuel'),
                  const SizedBox(width: 16),
                  _buildLegendDot(AppColors.secondaryTeal, 'Service'),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.purple.shade400, 'Other'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMileageLineChartCard(VehicleStatisticsSummary stats) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final points = stats.mileageTrend;

    double minMileage = stats.worstMileage;
    double maxMileage = stats.bestMileage;
    if (minMileage == maxMileage) {
      minMileage = (minMileage - 2).clamp(0, 100);
      maxMileage = maxMileage + 2;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fuel Efficiency Trend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Avg: ${stats.avgMileage.toStringAsFixed(1)} ${settings.economyUnit}',
                      style: const TextStyle(
                        color: AppColors.primaryAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Full-to-full calculated economy across fill-ups',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: math.max(0, minMileage - 1),
                    maxY: maxMileage + 1,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            if (idx < 0 || idx >= points.length) return null;
                            final pt = points[idx];
                            return LineTooltipItem(
                              '${pt.formattedDate}\n',
                              const TextStyle(color: Colors.white70, fontSize: 11),
                              children: [
                                TextSpan(
                                  text: '${pt.mileage.toStringAsFixed(2)} ${settings.economyUnit}',
                                  style: const TextStyle(
                                    color: AppColors.primaryAmber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: math.max(1, (points.length / 4).floor()).toDouble(),
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                points[idx].formattedDate,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        if (stats.avgMileage > 0)
                          HorizontalLine(
                            y: stats.avgMileage,
                            color: AppColors.primaryAmber.withValues(alpha: 0.5),
                            strokeWidth: 1.5,
                            dashArray: [5, 5],
                          ),
                      ],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value.mileage);
                        }).toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: AppColors.primaryAmber,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.primaryAmber,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primaryAmber.withValues(alpha: 0.3),
                              AppColors.primaryAmber.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(VehicleStatisticsSummary stats) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Other Expenses by Category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...stats.expenseCategoryBreakdown.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon ?? Icons.payments_rounded, color: cat.color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.label,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${settings.currencySymbol} ${cat.amount.toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: cat.color),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${cat.percentage.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (cat.percentage / 100).clamp(0.0, 1.0),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insert_chart_outlined_rounded,
                size: 56,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Statistics Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log fill-ups, services, and other expenses for this vehicle to generate rich charts and cost insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
