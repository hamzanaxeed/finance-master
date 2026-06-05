# WealthTracker - Flutter Application

A comprehensive personal finance management application built with Flutter, Dart, Riverpod, and Go Router.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # App configuration
├── core/
│   ├── router/
│   │   └── app_router.dart           # Go Router configuration
│   └── theme/
│       └── app_theme.dart            # Material 3 theme
├── shared/
│   ├── models/
│   │   ├── account.dart              # Account model
│   │   ├── transaction.dart          # Transaction model
│   │   ├── budget.dart               # Budget model
│   │   ├── loan.dart                 # Loan model
│   │   └── portfolio.dart            # Portfolio models
│   ├── providers/
│   │   ├── account_provider.dart     # Riverpod account state
│   │   ├── transaction_provider.dart # Riverpod transaction state
│   │   ├── budget_provider.dart      # Riverpod budget state
│   │   ├── loan_provider.dart        # Riverpod loan state
│   │   └── portfolio_provider.dart   # Riverpod portfolio state
│   └── widgets/
│       └── bottom_navigation.dart    # Bottom navigation bar
├── features/
│   ├── dashboard/
│   │   ├── screens/
│   │   │   └── dashboard_screen.dart
│   │   └── widgets/
│   │       ├── stat_card.dart
│   │       └── quick_link_card.dart
│   ├── accounts/
│   │   └── screens/
│   │       ├── accounts_list_screen.dart
│   │       ├── add_account_screen.dart
│   │       ├── edit_account_screen.dart
│   │       └── account_details_screen.dart
│   ├── transactions/
│   │   └── screens/
│   │       ├── transactions_list_screen.dart
│   │       ├── add_transaction_screen.dart
│   │       └── transaction_details_screen.dart
│   ├── budgets/
│   │   └── screens/
│   │       ├── budgets_list_screen.dart
│   │       └── budget_details_screen.dart
│   ├── liabilities/
│   │   └── screens/
│   │       ├── loans_list_screen.dart
│   │       └── loan_details_screen.dart
│   ├── portfolio/
│   │   └── screens/
│   │       ├── portfolio_screen.dart
│   │       ├── portfolio_holdings_screen.dart
│   │       ├── add_stock_transaction_screen.dart
│   │       ├── portfolio_transactions_screen.dart
│   │       ├── dividends_screen.dart
│   │       └── corporate_actions_screen.dart
│   ├── reports/
│   │   └── screens/
│   │       └── reports_screen.dart
│   ├── analytics/
│   │   └── screens/
│   │       ├── analytics_screen.dart
│   │       └── activity_timeline_screen.dart
│   └── more/
│       └── screens/
│           └── more_screen.dart
```

## Features

### 1. Dashboard
- **Total Assets Display**: Shows net worth with gain/loss percentage
- **Monthly Income & Expense**: Current month financial overview
- **Cashflow Indicator**: Surplus or deficit tracking
- **Recent Transactions**: Last 5 transactions with quick navigation
- **Quick Links**: Fast access to Transactions, Budgets, Loans, Analytics

### 2. Accounts Management
- **Account Types**: Bank, Wallet, Savings, Investment, Cash
- **Multi-Currency Support**: PKR, USD, EUR, GBP, JPY, AUD, CAD, CHF
- **CRUD Operations**: Create, Read, Update, Delete accounts
- **Balance Tracking**: Initial balance vs current balance with gain calculation
- **Account Details**: Transaction history filtered by account

### 3. Transactions
- **Transaction Types**: Income, Expense, Transfer
- **Categories**: 
  - Income: Salary, Freelance, Investment, Business, Gift
  - Expense: Food, Shopping, Transportation, Bills, Entertainment, Healthcare
- **Filtering**: By type, account, category, date range
- **Notes**: Optional transaction notes
- **Date Tracking**: Transaction date with created timestamp

### 4. Budgets
- **Monthly Limits**: Set budget limits per category
- **Spending Tracking**: Real-time spent amount vs limit
- **Progress Indicators**: Visual progress bars with color coding
- **Alerts**: Over-budget warnings
- **Period Filtering**: By month/year

### 5. Loans & Liabilities
- **Loan Types**: Personal, Home, Auto, Education, Business
- **Payment Tracking**: Monthly installment, interest rate
- **Progress**: Percentage paid vs remaining
- **Due Dates**: Start date and due date tracking
- **Payment Actions**: Make payment functionality

### 6. Portfolio Management
- **Stock Holdings**: Auto-calculated from buy/sell transactions
- **Transaction Types**: Buy, Sell with commission tracking
- **Dividends**: Track dividend income by stock
- **Corporate Actions**: Stock splits, bonus shares, rights issues
- **P&L Calculation**: Profit/Loss per holding and overall portfolio
- **Allocation**: Portfolio allocation visualization

### 7. Analytics
- **Net Worth Growth**: Historical net worth chart
- **Asset Allocation**: Pie chart of asset distribution
- **Monthly Cashflow**: Income vs Expense bar chart
- **Budget Performance**: Category-wise budget utilization
- **Key Metrics**: Savings rate, debt-to-income, investment return

### 8. Activity Timeline
- **Combined Activities**: All financial activities in chronological order
- **Activity Types**: Transactions, stock trades, dividends, budget alerts, loan payments
- **Date Grouping**: Activities grouped by date
- **Visual Indicators**: Color-coded icons for each activity type

### 9. Reports
- **Report Types**:
  - Monthly Finance Report
  - Investment Report
  - Dividend Income Report
  - Net Worth Report
  - Budget Performance Report
- **Export Options**: PDF, CSV, Excel (simulated)
- **Real-time Data**: Generated from current data

### 10. More/Settings
- **Feature Access**: Organized menu for all features
- **Categories**:
  - Financial Management
  - Portfolio
  - Analytics & Reports
  - Settings
- **Theme Toggle**: Dark/Light mode switch
- **Profile**: User profile display

## State Management

### Riverpod Providers

All state is managed using Riverpod StateNotifiers:

```dart
// Account State
final accountProvider = StateNotifierProvider<AccountNotifier, List<Account>>((ref) {
  return AccountNotifier();
});

// Computed States
final totalAssetsProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountProvider);
  return accounts.fold(0.0, (sum, account) => sum + account.currentBalance);
});
```

### Provider Usage

```dart
// In widgets
final accounts = ref.watch(accountProvider);
final totalAssets = ref.watch(totalAssetsProvider);

// Mutations
ref.read(accountProvider.notifier).addAccount(account);
ref.read(accountProvider.notifier).updateAccount(id, account);
```

## Navigation

### Go Router Configuration

```dart
GoRoute(
  path: '/accounts',
  builder: (context, state) => const AccountsListScreen(),
),
GoRoute(
  path: '/accounts/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return AccountDetailsScreen(accountId: id);
  },
),
```

### Navigation Usage

```dart
// Navigate to route
context.push('/accounts/add');

// Navigate with parameters
context.push('/accounts/$id');

// Navigate back
context.pop();

// Replace current route
context.go('/more');
```

## Theming

### Material 3

The app uses Material 3 design with custom theme configuration:

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: Brightness.light,
  ),
  textTheme: GoogleFonts.interTextTheme(),
)
```

### Dark Mode

Dark mode is managed via Riverpod:

```dart
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

// Toggle dark mode
ref.read(darkModeProvider.notifier).toggle();
```

## Data Models

### Account Model
```dart
class Account {
  final String id;
  final String name;
  final AccountType type;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final DateTime lastActivity;
  final DateTime createdAt;
  
  double get gain => currentBalance - initialBalance;
  double get gainPercent => ...;
}
```

### Transaction Model
```dart
class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final String accountId;
  final DateTime date;
  final String? notes;
}
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1  # State management
  go_router: ^14.0.0         # Routing
  fl_chart: ^0.68.0          # Charts
  google_fonts: ^6.1.0       # Typography
  intl: ^0.19.0              # Internationalization
  uuid: ^4.3.3               # Unique IDs
```

## Getting Started

### Installation

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Build for production
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

### Development

```bash
# Run with hot reload
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

## Key Features Converted from React

| React Feature | Flutter Equivalent |
|--------------|-------------------|
| React Components | Flutter Widgets |
| React Context | Riverpod Providers |
| React Router | Go Router |
| useState | StatefulWidget / StateNotifier |
| useEffect | initState / didUpdateWidget |
| Recharts | fl_chart |
| Tailwind CSS | Theme / BoxDecoration |
| Sonner | SnackBar |
| Lucide Icons | Material Icons |

## Architecture Patterns

### Feature-First Structure
Each feature is self-contained with its screens and widgets.

### Repository Pattern
Ready for database integration - providers can be replaced with repositories.

### Presentation Separation
Business logic in providers, UI in widgets.

## Future Enhancements

- [ ] Add fl_chart implementations for all charts
- [ ] Implement actual PDF/CSV/Excel export
- [ ] Add authentication
- [ ] Integrate with backend API
- [ ] Add local database (SQLite/Hive)
- [ ] Add biometric authentication
- [ ] Implement notifications
- [ ] Add cloud sync

## License

© 2026 WealthTracker. All rights reserved.
