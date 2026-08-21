import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/company_admin_home_page.dart';
import '../../features/auth/presentation/pages/employee_home_page.dart';
import '../../features/companies/domain/entities/company.dart';
import '../../features/companies/presentation/pages/companies_page.dart';
import '../../features/companies/presentation/pages/create_company_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/sales/presentation/pages/create_sale_page.dart';
import '../../features/sales/presentation/pages/sale_detail_page.dart';
import '../../features/sales/domain/entities/sale.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/customers/presentation/pages/create_customer_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/customers/domain/entities/customer.dart';
import '../../features/purchases/presentation/pages/purchases_page.dart';
import '../../features/purchases/presentation/pages/create_purchase_page.dart';
import '../../features/purchases/presentation/pages/purchase_detail_page.dart';
import '../../features/purchases/domain/entities/purchase.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/expenses/presentation/pages/create_expense_page.dart';
import '../../features/expenses/presentation/pages/expense_detail_page.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../../features/employees/presentation/pages/employees_page.dart';
import '../../features/employees/presentation/pages/create_employee_page.dart';
import '../../features/employees/presentation/pages/employee_detail_page.dart';
import '../../features/employees/domain/entities/employee.dart';
import '../../features/security/presentation/cubit/security_cubit.dart';
import '../../features/security/presentation/pages/lock_screen_page.dart';
import '../../features/security/presentation/pages/pin_setup_page.dart';
import '../../features/security/presentation/pages/security_settings_page.dart';
import '../../features/security/presentation/pages/set_pin_page.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String companies = '/companies';       // super admin home
  static const String companyAdminHome = '/admin';    // company admin home
  static const String employeeHome = '/home';         // employee home
  static const String createCompany = '/companies/create';
  static const String sales = '/sales';
  static const String createSale = '/sales/create';
  static const String saleDetail = '/sales/detail';
  static const String customers = '/customers';
  static const String createCustomer = '/customers/create';
  static const String customerDetail = '/customers/detail';
  static const String purchases = '/purchases';
  static const String createPurchase = '/purchases/create';
  static const String purchaseDetail = '/purchases/detail';
  static const String expenses = '/expenses';
  static const String createExpense = '/expenses/create';
  static const String expenseDetail = '/expenses/detail';
  static const String employees = '/employees';
  static const String createEmployee = '/employees/create';
  static const String employeeDetail = '/employees/detail';
  static const String lockScreen = '/lock';
  static const String security = '/security';
  static const String setPin = '/security/set-pin';
  static const String pinSetup = '/security/pin-setup';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: companies,
        builder: (context, state) => CompaniesPage(initialSection: state.extra as String?),
      ),
      GoRoute(
        path: companyAdminHome,
        builder: (context, state) => const CompanyAdminHomePage(),
      ),
      GoRoute(
        path: employeeHome,
        builder: (context, state) => const EmployeeHomePage(),
      ),
      GoRoute(
        path: createCompany,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return CreateCompanyPage(editCompany: extra['edit'] as Company?);
          }
          return CreateCompanyPage(fromMenu: extra == 'menu');
        },
      ),
      GoRoute(
        path: sales,
        builder: (context, state) => SalesPage(fromMasters: state.extra == 'masters'),
      ),
      GoRoute(
        path: createSale,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return CreateSalePage(
              fromMasters: extra['fromMasters'] == true,
              fromMenu: extra['fromMenu'] == true,
              editSale: extra['sale'] as Sale?,
            );
          }
          return CreateSalePage(
            fromMenu: extra == 'menu',
            fromMasters: extra == 'masters',
          );
        },
      ),
      GoRoute(
        path: saleDetail,
        builder: (context, state) => SaleDetailPage(sale: state.extra as Sale),
      ),
      GoRoute(
        path: customers,
        builder: (context, state) => CustomersPage(fromMasters: state.extra == 'masters'),
      ),
      GoRoute(
        path: createCustomer,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Customer) return CreateCustomerPage(editCustomer: extra);
          return CreateCustomerPage(fromMasters: extra == 'masters');
        },
      ),
      GoRoute(
        path: customerDetail,
        builder: (context, state) => CustomerDetailPage(customer: state.extra as Customer),
      ),
      GoRoute(
        path: purchases,
        builder: (context, state) => PurchasesPage(fromMasters: state.extra == 'masters'),
      ),
      GoRoute(
        path: createPurchase,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return CreatePurchasePage(
              fromMasters: extra['fromMasters'] == true,
              editPurchase: extra['purchase'] as Purchase?,
            );
          }
          return CreatePurchasePage(fromMasters: extra == 'masters');
        },
      ),
      GoRoute(
        path: purchaseDetail,
        builder: (context, state) => PurchaseDetailPage(purchase: state.extra as Purchase),
      ),
      GoRoute(
        path: expenses,
        builder: (context, state) => ExpensesPage(fromMasters: state.extra == 'masters'),
      ),
      GoRoute(
        path: createExpense,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Expense) return CreateExpensePage(editExpense: extra);
          return CreateExpensePage(fromMasters: extra == 'masters');
        },
      ),
      GoRoute(
        path: expenseDetail,
        builder: (context, state) => ExpenseDetailPage(expense: state.extra as Expense),
      ),
      GoRoute(
        path: employees,
        builder: (context, state) => EmployeesPage(fromMasters: state.extra == 'masters'),
      ),
      GoRoute(
        path: createEmployee,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Employee) return CreateEmployeePage(editEmployee: extra);
          return CreateEmployeePage(fromMasters: extra == 'masters');
        },
      ),
      GoRoute(
        path: employeeDetail,
        builder: (context, state) => EmployeeDetailPage(employee: state.extra as Employee),
      ),
      GoRoute(
        path: pinSetup,
        builder: (context, state) => const PinSetupPage(),
      ),
      GoRoute(
        path: lockScreen,
        builder: (context, state) => BlocProvider.value(
          value: securityCubit,
          child: const LockScreenPage(),
        ),
      ),
      GoRoute(
        path: security,
        builder: (context, state) => BlocProvider.value(
          value: securityCubit,
          child: const SecuritySettingsPage(),
        ),
      ),
      GoRoute(
        path: setPin,
        builder: (context, state) => BlocProvider.value(
          value: securityCubit,
          child: const SetPinPage(),
        ),
      ),
    ],
  );
}
