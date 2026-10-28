import 'package:flutter/material.dart';

class ExpenseCategoryHelper {
  /// Returns an appropriate icon for a given category code or name.
  static IconData getCategoryIcon(String? code, [String? name]) {
    final key = (code ?? name ?? '').toLowerCase();

    if (key.contains('parking')) {
      return Icons.local_parking_rounded;
    } else if (key.contains('toll')) {
      return Icons.toll_rounded;
    } else if (key.contains('wash')) {
      return Icons.local_car_wash_rounded;
    } else if (key.contains('fine')) {
      return Icons.gavel_rounded;
    } else if (key.contains('insurance')) {
      return Icons.health_and_safety_rounded;
    } else if (key.contains('reg') || key.contains('tax') || key.contains('token')) {
      return Icons.receipt_long_rounded;
    } else if (key.contains('accessories') || key.contains('mod')) {
      return Icons.car_repair_rounded;
    } else if (key.contains('loan') || key.contains('emi') || key.contains('lease')) {
      return Icons.account_balance_rounded;
    } else if (key.contains('fuel')) {
      return Icons.local_gas_station_rounded;
    } else if (key.contains('service') || key.contains('maintenance')) {
      return Icons.build_rounded;
    }

    return Icons.payments_rounded;
  }

  /// Returns a harmonious accent color for the expense category.
  static Color getCategoryColor(String? code, [String? name]) {
    final key = (code ?? name ?? '').toLowerCase();

    if (key.contains('parking')) {
      return const Color(0xFF3B82F6); // Blue
    } else if (key.contains('toll')) {
      return const Color(0xFFF97316); // Orange
    } else if (key.contains('wash')) {
      return const Color(0xFF06B6D4); // Cyan
    } else if (key.contains('fine')) {
      return const Color(0xFFEF4444); // Red
    } else if (key.contains('insurance')) {
      return const Color(0xFF10B981); // Emerald
    } else if (key.contains('reg') || key.contains('tax')) {
      return const Color(0xFF8B5CF6); // Purple
    } else if (key.contains('accessories')) {
      return const Color(0xFFEC4899); // Pink
    } else if (key.contains('loan') || key.contains('emi')) {
      return const Color(0xFF6366F1); // Indigo
    }

    return const Color(0xFF64748B); // Slate
  }
}
