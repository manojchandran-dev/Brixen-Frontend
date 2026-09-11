import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/dashboard_home_page.dart';
import '../../features/auth/presentation/pages/report_home_page.dart';
import '../../features/auth/presentation/pages/more_home_page.dart';
import '../../features/companies/domain/entities/company.dart';
import '../../features/companies/presentation/pages/companies_page.dart';
import '../../features/companies/presentation/pages/create_company_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/sales/presentation/pages/create_sale_page.dart';
import '../../features/sales/domain/entities/sale.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/customers/presentation/pages/create_customer_page.dart';
import '../../features/customers/domain/entities/customer.dart';
import '../../features/purchases/presentation/pages/purchases_page.dart';
import '../../features/purchases/presentation/pages/create_purchase_page.dart';
import '../../features/purchases/domain/entities/purchase.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/expenses/presentation/pages/create_expense_page.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../../features/employees/presentation/pages/employees_page.dart';
import '../../features/employees/presentation/pages/create_employee_page.dart';
import '../../features/employees/domain/entities/employee.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/products/presentation/pages/create_product_page.dart';
import '../../features/products/domain/entities/product.dart';
import '../../features/permissions/presentation/pages/permission_management_page.dart';
import '../../features/permissions/presentation/pages/create_permission_page.dart';
import '../../features/permissions/presentation/pages/module_access_page.dart';
import '../../features/masters/presentation/pages/master_category_page.dart';
import '../../features/security/presentation/cubit/security_cubit.dart';
import '../../features/security/presentation/pages/lock_screen_page.dart';
import '../../features/security/presentation/pages/pin_setup_page.dart';
import '../../features/security/presentation/pages/security_settings_page.dart';
import '../../features/security/presentation/pages/set_pin_page.dart';

class AppRouter {
  AppRouter._();

  // `CompaniesPage` reads its section from the route's `extra` and re-syncs
  // internal nav state in `didUpdateWidget` whenever it changes. If you
  // navigate to the exact same section twice in a row (e.g. tap "Companies"
  // in the drawer, browse elsewhere inside the page without leaving the
  // route, then tap "Companies" again), the plain string is identical to
  // last time, which occasionally isn't enough for GoRouter/Flutter's page
  // diffing to treat it as a fresh update — the tap silently does nothing.
  // Appending a unique nonce guarantees every tap is a distinct value.
  static String companiesSection(String section) =>
      '$section#${DateTime.now().microsecondsSinceEpoch}';

  static const String splash = RouteNames.splash;
  static const String signIn = RouteNames.signIn;
  static const String signUp = RouteNames.signUp;
  static const String forgotPassword = RouteNames.forgotPassword;
  static const String companies = RouteNames.companies; // super admin's company-management hub, reached via the drawer
  static const String createCompany = RouteNames.createCompany;
  static const String dashboard = RouteNames.dashboard; // shared landing page for every role after PIN verification
  static const String report = RouteNames.report; // shared Report tab, same for every role
  static const String more = RouteNames.more; // shared More tab, same for every role
  static const String sales = RouteNames.sales;
  static const String createSale = RouteNames.createSale;
  static const String customers = RouteNames.customers;
  static const String createCustomer = RouteNames.createCustomer;
  static const String purchases = RouteNames.purchases;
  static const String createPurchase = RouteNames.createPurchase;
  static const String expenses = RouteNames.expenses;
  static const String createExpense = RouteNames.createExpense;
  static const String employees = RouteNames.employees;
  static const String createEmployee = RouteNames.createEmployee;
  static const String products = RouteNames.products;
  static const String createProduct = RouteNames.createProduct;
  static const String permissions = RouteNames.permissions;
  static const String createPermission = RouteNames.createPermission;
  static const String moduleAccess = RouteNames.moduleAccess;
  static const String masterCompanyCategories = RouteNames.masterCompanyCategories;
  static const String masterExpenseCategories = RouteNames.masterExpenseCategories;
  static const String masterProductCategories = RouteNames.masterProductCategories;
  static const String masterUnits = RouteNames.masterUnits;
  static const String lockScreen = RouteNames.lockScreen;
  static const String security = RouteNames.security;
  static const String setPin = RouteNames.setPin;
  static const String pinSetup = RouteNames.pinSetup;

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: signIn, builder: (context, state) => const SignInPage()),
      GoRoute(path: signUp, builder: (context, state) => const SignUpPage()),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: companies,
        builder: (context, state) =>
            CompaniesPage(initialSection: state.extra as String?),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardHomePage(),
      ),
      GoRoute(
        path: report,
        builder: (context, state) => const ReportHomePage(),
      ),
      GoRoute(
        path: more,
        builder: (context, state) => const MoreHomePage(),
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
        builder: (context, state) =>
            SalesPage(fromMasters: state.extra == 'masters'),
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
        path: customers,
        builder: (context, state) =>
            CustomersPage(fromMasters: state.extra == 'masters'),
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
        path: purchases,
        builder: (context, state) =>
            PurchasesPage(fromMasters: state.extra == 'masters'),
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
        path: expenses,
        builder: (context, state) =>
            ExpensesPage(fromMasters: state.extra == 'masters'),
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
        path: employees,
        builder: (context, state) =>
            EmployeesPage(fromMasters: state.extra == 'masters'),
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
        path: products,
        builder: (context, state) =>
            ProductsPage(fromMasters: state.extra == 'masters'),
      ),
      GoRoute(
        path: createProduct,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Product) return CreateProductPage(editProduct: extra);
          return CreateProductPage(fromMasters: extra == 'masters');
        },
      ),
      GoRoute(
        path: permissions,
        builder: (context, state) => const PermissionManagementPage(),
      ),
      GoRoute(
        path: createPermission,
        builder: (context, state) =>
            CreatePermissionPage(company: state.extra as Company?),
      ),
      GoRoute(
        path: moduleAccess,
        builder: (context, state) {
          final extra = state.extra as Map;
          return ModuleAccessPage(
            companyId: extra['companyId'] as String,
            moduleKey: extra['moduleKey'] as String,
          );
        },
      ),
      GoRoute(
        path: masterCompanyCategories,
        builder: (context, state) => const MasterCategoryPage(typeKey: 'companyCategory'),
      ),
      GoRoute(
        path: masterExpenseCategories,
        builder: (context, state) => const MasterCategoryPage(typeKey: 'expenseCategory'),
      ),
      GoRoute(
        path: masterProductCategories,
        builder: (context, state) => const MasterCategoryPage(typeKey: 'productCategory'),
      ),
      GoRoute(
        path: masterUnits,
        builder: (context, state) => const MasterCategoryPage(typeKey: 'unit'),
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
        builder: (context, state) =>
            BlocProvider.value(value: securityCubit, child: const SetPinPage()),
      ),
    ],
  );
}
