import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/accounts/screens/accounts_list_screen.dart';
import '../../features/accounts/screens/add_account_screen.dart';
import '../../features/accounts/screens/edit_account_screen.dart';
import '../../features/accounts/screens/account_details_screen.dart';
import '../../features/transactions/screens/transactions_list_screen.dart';
import '../../features/transactions/screens/add_transaction_screen.dart';
import '../../features/transactions/screens/transaction_details_screen.dart';
import '../../features/portfolio/screens/portfolio_screen.dart';
import '../../features/portfolio/screens/portfolio_holdings_screen.dart';
import '../../features/portfolio/screens/add_stock_transaction_screen.dart';
import '../../features/portfolio/screens/portfolio_transactions_screen.dart';
import '../../features/portfolio/screens/dividends_screen.dart';
import '../../features/portfolio/screens/charges_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/analytics/screens/activity_timeline_screen.dart';
import '../../features/more/screens/more_screen.dart';
import '../../features/more/screens/notes_screen.dart';
import '../../features/more/screens/passwords_screen.dart';
import 'package:wealthtracker/features/more/screens/manage_categories_screen.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../../features/portfolio/screens/portfolio_holding_detail_screen.dart';
import '../../features/more/screens/backup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsListScreen(),
          ),
          GoRoute(
            path: '/portfolio',
            builder: (context, state) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsListScreen(),
          ),
          GoRoute(
            path: '/manage-categories',
            builder: (context, state) => const ManageCategoriesScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
          GoRoute(
            path: '/more/backup',
            builder: (context, state) => const BackupScreen(),
          ),
          GoRoute(
            path: '/more/notes',
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: '/more/passwords',
            builder: (context, state) => const PasswordsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts/add',
        builder: (context, state) => const AddAccountScreen(),
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditAccountScreen(accountId: id);
        },
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AccountDetailsScreen(accountId: id);
        },
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionDetailsScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/portfolio/holdings',
        builder: (context, state) => const PortfolioHoldingsScreen(),
      ),
      GoRoute(
        path: '/portfolio/holdings/:symbol',
        builder: (context, state) {
          final symbol = state.pathParameters['symbol']!;
          return HoldingDetailScreen(symbol: symbol);
        },
      ),
      GoRoute(
        path: '/portfolio/add-transaction',
        builder: (context, state) => const AddStockTransactionScreen(),
      ),
      GoRoute(
        path: '/portfolio/transactions',
        builder: (context, state) => const PortfolioTransactionsScreen(),
      ),
      GoRoute(
        path: '/portfolio/dividends',
        builder: (context, state) => const DividendsScreen(),
      ),
      GoRoute(
        path: '/portfolio/charges',
        builder: (context, state) => const ChargesScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const ActivityTimelineScreen(),
      ),
    ],
  );
});
