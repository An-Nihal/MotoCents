import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/expenses/presentation/expense_detail_screen.dart';
import '../../features/expenses/presentation/expense_form_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/fuel/presentation/fuel_screen.dart';
import '../../features/garage/presentation/vehicles_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/service/presentation/service_screen.dart';
import '../../features/shell/presentation/navigation_shell.dart';
import '../../features/smart/presentation/station_insights_screen.dart';
import '../../features/smart/presentation/trip_cost_calculator_screen.dart';
import '../../features/backup/presentation/backup_restore_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/manage_document_types_screen.dart';
import '../../features/settings/presentation/manage_expense_categories_screen.dart';
import '../../features/settings/presentation/manage_service_types_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Fuel
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fuel',
                builder: (context, state) => const FuelScreen(),
              ),
            ],
          ),
          // Branch 2: Service
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/service',
                builder: (context, state) => const ServiceScreen(),
              ),
            ],
          ),
          // Branch 3: Documents
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) => const DocumentsScreen(),
              ),
            ],
          ),
          // Branch 4: More
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/garage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VehiclesListScreen(),
      ),
      GoRoute(
        path: '/expenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpensesScreen(),
        routes: [
          GoRoute(
            path: 'add',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const ExpenseFormScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ExpenseDetailScreen(expenseId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/statistics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/station-insights',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StationInsightsScreen(),
      ),
      GoRoute(
        path: '/trip-calculator',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TripCostCalculatorScreen(),
      ),
      GoRoute(
        path: '/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/backup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BackupRestoreScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/manage-service-types',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageServiceTypesScreen(),
      ),
      GoRoute(
        path: '/manage-expense-categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageExpenseCategoriesScreen(),
      ),
      GoRoute(
        path: '/manage-document-types',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageDocumentTypesScreen(),
      ),
    ],
  );
});
