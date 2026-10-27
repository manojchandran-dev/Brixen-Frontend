import 'package:flutter/widgets.dart' show PopScope, SizedBox;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/module_guard.dart';
import '../../features/masters/domain/entities/master_type.dart'
    show masterModuleName;
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/employees/presentation/pages/staff_permissions_pages.dart';
import 'route_names.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
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
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/payroll/presentation/pages/salary_generation_pages.dart';
import '../../features/employees/presentation/pages/employees_page.dart';
import '../../features/employees/presentation/pages/create_employee_page.dart';
import '../../features/employees/domain/entities/employee.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/products/presentation/pages/create_product_page.dart';
import '../../features/products/domain/entities/product.dart';
import '../../features/permissions/presentation/pages/permission_management_page.dart';
import '../../features/permissions/presentation/pages/create_permission_page.dart';
import '../../features/permissions/presentation/pages/module_access_page.dart';
import '../../features/notifications/domain/entities/push_notification.dart';
import '../../features/notifications/domain/entities/announcement.dart';
import '../../features/notifications/presentation/pages/push_notifications_page.dart';
import '../../features/notifications/presentation/pages/create_push_notification_page.dart';
import '../../features/notifications/presentation/pages/announcements_page.dart';
import '../../features/notifications/presentation/pages/create_announcement_page.dart';
import '../../features/support/domain/entities/support_ticket.dart';
import '../../features/support/presentation/pages/support_tickets_page.dart';
import '../../features/support/presentation/pages/create_ticket_page.dart';
import '../../features/support/presentation/pages/ticket_detail_page.dart';
import '../../features/support/presentation/pages/ticket_manage_page.dart';
import '../services/session_service.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/masters/presentation/pages/master_category_page.dart';
import '../../features/security/presentation/cubit/security_cubit.dart';
import '../../features/security/presentation/pages/lock_screen_page.dart';
import '../../features/security/presentation/pages/pin_setup_page.dart';
import '../../features/security/presentation/pages/security_settings_page.dart';
import '../../features/security/presentation/pages/set_pin_page.dart';
import '../../shared/widgets/exit_guard.dart';

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
  static const String profile = RouteNames.profile;
  static const String changePassword = RouteNames.changePassword;
  static const String companies = RouteNames
      .companies; // super admin's company-management hub, reached via the drawer
  static const String createCompany = RouteNames.createCompany;
  static const String dashboard = RouteNames
      .dashboard; // shared landing page for every role after PIN verification
  static const String report =
      RouteNames.report; // shared Report tab, same for every role
  static const String more =
      RouteNames.more; // shared More tab, same for every role
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
  static const String inventory = RouteNames.inventory;
  static const String attendance = RouteNames.attendance;
  static const String staffPermissions = RouteNames.staffPermissions;
  static const String salaryGeneration = RouteNames.salaryGeneration;
  static const String createProduct = RouteNames.createProduct;
  static const String permissions = RouteNames.permissions;
  static const String createPermission = RouteNames.createPermission;
  static const String moduleAccess = RouteNames.moduleAccess;
  static const String pushNotifications = RouteNames.pushNotifications;
  static const String createPushNotification =
      RouteNames.createPushNotification;
  static const String announcements = RouteNames.announcements;
  static const String createAnnouncement = RouteNames.createAnnouncement;
  static const String support = RouteNames.support;
  static const String createTicket = RouteNames.createTicket;
  static const String ticketDetail = RouteNames.ticketDetail;
  static const String chat = RouteNames.chat;
  static const String chatRoom = RouteNames.chatRoom;
  static const String masterCompanyCategories =
      RouteNames.masterCompanyCategories;
  static const String masterExpenseCategories =
      RouteNames.masterExpenseCategories;
  static const String masterProductCategories =
      RouteNames.masterProductCategories;
  static const String masterPurchaseCategories =
      RouteNames.masterPurchaseCategories;
  static const String masterUnits = RouteNames.masterUnits;
  static const String masterDepartments = RouteNames.masterDepartments;
  static const String masterWorkTypes = RouteNames.masterWorkTypes;
  static const String lockScreen = RouteNames.lockScreen;
  static const String security = RouteNames.security;
  static const String setPin = RouteNames.setPin;
  static const String pinSetup = RouteNames.pinSetup;

  /// [child]'s path relative to [parent] — go_router nested routes take
  /// relative paths, while [RouteNames] keeps the full ones for go/push.
  static String _sub(String child, String parent) {
    assert(child.startsWith('$parent/'), '$child is not under $parent');
    return child.substring(parent.length + 1);
  }

  /// [builder]'s page, shown only to a user who may view [module] — so an
  /// address typed or saved can't open a screen the menu hides.
  static GoRouterWidgetBuilder _guard(
    String module,
    GoRouterWidgetBuilder builder,
  ) =>
      (context, state) =>
          ModuleGuard(module: module, child: builder(context, state));

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashPage()),
      GoRoute(
        path: signIn,
        builder: (context, state) =>
            ExitGuard(child: SignInPage(initialEmail: state.extra as String?)),
      ),
      GoRoute(path: signUp, builder: (context, state) => const SignUpPage()),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: dashboard,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ExitGuard(child: DashboardHomePage()),
        ),
        routes: [
          GoRoute(
            path: _sub(companies, dashboard),
            builder: (context, state) =>
                CompaniesPage(initialSection: state.extra as String?),
            routes: [
              GoRoute(
                path: _sub(createCompany, companies),
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is Map) {
                    return CreateCompanyPage(
                      editCompany: extra['edit'] as Company?,
                    );
                  }
                  return CreateCompanyPage(fromMenu: extra == 'menu');
                },
              ),
            ],
          ),
          GoRoute(
            path: _sub(report, dashboard),
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportHomePage()),
          ),
          GoRoute(
            path: _sub(more, dashboard),
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MoreHomePage()),
          ),
          GoRoute(
            path: _sub(sales, dashboard),
            builder: _guard(
              'Sales',
              (context, state) =>
                  SalesPage(fromMasters: state.extra == 'masters'),
            ),
            routes: [
              GoRoute(
                path: _sub(createSale, sales),
                builder: _guard('Sales', (context, state) {
                  final extra = state.extra;
                  if (extra is Map) {
                    return CreateSalePage(
                      fromMasters: extra['fromMasters'] == true,
                      fromMenu: extra['fromMenu'] == true,
                      editSale: extra['sale'] as Sale?,
                      billType: extra['billType'] as String? ?? BillType.gst,
                    );
                  }
                  return CreateSalePage(
                    fromMenu: extra == 'menu',
                    fromMasters: extra == 'masters',
                  );
                }),
              ),
            ],
          ),
          GoRoute(
            path: _sub(customers, dashboard),
            builder: _guard(
              'Customers',
              (context, state) =>
                  CustomersPage(fromMasters: state.extra == 'masters'),
            ),
            routes: [
              GoRoute(
                path: _sub(createCustomer, customers),
                builder: _guard('Customers', (context, state) {
                  final extra = state.extra;
                  if (extra is Customer) {
                    return CreateCustomerPage(editCustomer: extra);
                  }
                  return CreateCustomerPage(fromMasters: extra == 'masters');
                }),
              ),
            ],
          ),
          GoRoute(
            path: _sub(purchases, dashboard),
            builder: _guard(
              'Purchases',
              (context, state) =>
                  PurchasesPage(fromMasters: state.extra == 'masters'),
            ),
            routes: [
              GoRoute(
                path: _sub(createPurchase, purchases),
                builder: _guard('Purchases', (context, state) {
                  final extra = state.extra;
                  if (extra is Map) {
                    return CreatePurchasePage(
                      fromMasters: extra['fromMasters'] == true,
                      editPurchase: extra['purchase'] as Purchase?,
                    );
                  }
                  return CreatePurchasePage(fromMasters: extra == 'masters');
                }),
              ),
            ],
          ),
          GoRoute(
            path: _sub(expenses, dashboard),
            builder: _guard(
              'Expenses',
              (context, state) =>
                  ExpensesPage(fromMasters: state.extra == 'masters'),
            ),
            routes: [
              GoRoute(
                path: _sub(createExpense, expenses),
                builder: _guard('Expenses', (context, state) {
                  final extra = state.extra;
                  if (extra is Expense) {
                    return CreateExpensePage(editExpense: extra);
                  }
                  return CreateExpensePage(fromMasters: extra == 'masters');
                }),
              ),
            ],
          ),
          GoRoute(
            path: _sub(employees, dashboard),
            builder: _guard(
              'Employees',
              (context, state) =>
                  EmployeesPage(fromMasters: state.extra == 'masters'),
            ),
            routes: [
              GoRoute(
                path: _sub(createEmployee, employees),
                builder: _guard('Employees', (context, state) {
                  final extra = state.extra;
                  if (extra is Employee) {
                    return CreateEmployeePage(editEmployee: extra);
                  }
                  return CreateEmployeePage(fromMasters: extra == 'masters');
                }),
              ),
            ],
          ),
          GoRoute(
            path: _sub(staffPermissions, dashboard),
            // Company admins only: employee logins never manage access.
            builder: _guard(
              'Employees',
              (context, state) => Session.role == UserRole.employee
                  ? const SizedBox.shrink()
                  : StaffPermissionsPage(
                      initialEmployeeId: state.extra as String?,
                    ),
            ),
          ),
          GoRoute(
            path: _sub(salaryGeneration, dashboard),
            // Salary generation is part of Employees.
            builder: _guard(
              'Employees',
              (context, state) => const SalaryGenerationPage(),
            ),
          ),
          GoRoute(
            path: _sub(inventory, dashboard),
            // Stock is part of a product: the Products permission.
            builder: _guard(
              'Products',
              (context, state) => const InventoryPage(),
            ),
          ),
          GoRoute(
            path: _sub(attendance, dashboard),
            builder: _guard(
              'Attendance',
              (context, state) => const AttendancePage(),
            ),
          ),
          GoRoute(
            path: _sub(products, dashboard),
            builder: _guard(
              'Products',
              (context, state) =>
                  ProductsPage(fromMasters: state.extra == 'masters'),
            ),
            routes: [
              GoRoute(
                path: _sub(createProduct, products),
                builder: _guard('Products', (context, state) {
                  final extra = state.extra;
                  if (extra is Product) {
                    return CreateProductPage(editProduct: extra);
                  }
                  return CreateProductPage(fromMasters: extra == 'masters');
                }),
              ),
            ],
          ),
          GoRoute(
            path: _sub(permissions, dashboard),
            builder: (context, state) => const PermissionManagementPage(),
            routes: [
              GoRoute(
                path: _sub(createPermission, permissions),
                builder: (context, state) =>
                    CreatePermissionPage(company: state.extra as Company?),
              ),
              GoRoute(
                path: _sub(moduleAccess, permissions),
                builder: (context, state) {
                  final extra = state.extra as Map;
                  return ModuleAccessPage(
                    companyId: extra['companyId'] as String,
                    moduleKey: extra['moduleKey'] as String,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: _sub(pushNotifications, dashboard),
            builder: (context, state) => const PushNotificationsPage(),
            routes: [
              GoRoute(
                path: _sub(createPushNotification, pushNotifications),
                builder: (context, state) => CreatePushNotificationPage(
                  editNotification: state.extra as PushNotification?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: _sub(announcements, dashboard),
            builder: (context, state) => const AnnouncementsPage(),
            routes: [
              GoRoute(
                path: _sub(createAnnouncement, announcements),
                builder: (context, state) => CreateAnnouncementPage(
                  editAnnouncement: state.extra as Announcement?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: _sub(support, dashboard),
            builder: (context, state) => const SupportTicketsPage(),
            routes: [
              GoRoute(
                path: _sub(createTicket, support),
                builder: (context, state) => const CreateTicketPage(),
              ),
              GoRoute(
                path: _sub(ticketDetail, support),
                builder: (context, state) {
                  final ticket = state.extra as SupportTicket;
                  return Session.isSuperAdmin
                      ? TicketManagePage(ticket: ticket)
                      : TicketDetailPage(ticket: ticket);
                },
              ),
            ],
          ),
          GoRoute(
            path: _sub(chat, dashboard),
            builder: (context, state) => const ChatPage(),
            routes: [
              GoRoute(
                path: _sub(chatRoom, chat),
                builder: (context, state) {
                  final extra = state.extra as Map;
                  return ChatRoomPage(
                    companyId: extra['companyId'] as String,
                    companyName: extra['companyName'] as String,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: _sub(masterCompanyCategories, dashboard),
            builder: (context, state) => ModuleGuard(
              module: masterModuleName('companyCategory'),
              child: const MasterCategoryPage(typeKey: 'companyCategory'),
            ),
          ),
          GoRoute(
            path: _sub(masterExpenseCategories, dashboard),
            builder: (context, state) => ModuleGuard(
              module: masterModuleName('expenseCategory'),
              child: const MasterCategoryPage(typeKey: 'expenseCategory'),
            ),
          ),
          GoRoute(
            path: _sub(masterProductCategories, dashboard),
            builder: (context, state) => ModuleGuard(
              module: masterModuleName('productCategory'),
              child: const MasterCategoryPage(typeKey: 'productCategory'),
            ),
          ),
          GoRoute(
            path: _sub(masterPurchaseCategories, dashboard),
            builder: (context, state) => ModuleGuard(
              module: masterModuleName('purchaseCategory'),
              child: const MasterCategoryPage(typeKey: 'purchaseCategory'),
            ),
          ),
          GoRoute(
            path: _sub(masterUnits, dashboard),
            builder: (context, state) => ModuleGuard(
              module: masterModuleName('unit'),
              child: const MasterCategoryPage(typeKey: 'unit'),
            ),
          ),
          GoRoute(
            path: _sub(masterDepartments, dashboard),
            builder: (context, state) => ModuleGuard(
              module: masterModuleName('department'),
              child: const MasterCategoryPage(typeKey: 'department'),
            ),
          ),
          GoRoute(
            path: _sub(masterWorkTypes, dashboard),
            builder: (context, state) => ModuleGuard(
              module: masterModuleName('workType'),
              child: const MasterCategoryPage(typeKey: 'workType'),
            ),
          ),
          GoRoute(
            path: _sub(profile, dashboard),
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: _sub(changePassword, profile),
                builder: (context, state) => const ChangePasswordPage(),
              ),
            ],
          ),
          GoRoute(
            path: _sub(security, dashboard),
            builder: (context, state) => BlocProvider.value(
              value: securityCubit,
              child: const SecuritySettingsPage(),
            ),
            routes: [
              GoRoute(
                path: _sub(setPin, security),
                builder: (context, state) => BlocProvider.value(
                  value: securityCubit,
                  child: const SetPinPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: pinSetup,
        builder: (context, state) => const ExitGuard(child: PinSetupPage()),
      ),
      GoRoute(
        path: lockScreen,
        // extra == true: pushed by AppLock over the page the user left, so
        // unlocking returns there and back can't skip it.
        builder: (context, state) => BlocProvider.value(
          value: securityCubit,
          child: state.extra == true
              ? const PopScope(
                  canPop: false,
                  child: LockScreenPage(resume: true),
                )
              : const ExitGuard(child: LockScreenPage()),
        ),
      ),
    ],
  );
}
