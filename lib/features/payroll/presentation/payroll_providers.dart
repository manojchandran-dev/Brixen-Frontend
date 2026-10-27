import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payroll_remote_datasource.dart';
import '../domain/payroll.dart';

/// Every salary month generated, newest first.
final payrollRunsProvider = FutureProvider.autoDispose<List<PayrollRun>>(
  (ref) => ref.read(payrollDatasourceProvider).runs(),
);

/// One month's run with its payslips.
final payrollRunProvider = FutureProvider.autoDispose
    .family<PayrollRun, String>(
      (ref, id) => ref.read(payrollDatasourceProvider).run(id),
    );

/// Finalized payslips, for the salary report (filtered by the report's
/// period on the device, like the expense report).
final salaryReportProvider = FutureProvider.autoDispose<List<Payslip>>(
  (ref) => ref.read(payrollDatasourceProvider).payslips(),
);

/// The signed-in employee's payslips.
final myPayslipsProvider = FutureProvider.autoDispose<List<Payslip>>(
  (ref) => ref.read(payrollDatasourceProvider).myPayslips(),
);

/// After a run changes: its list, its detail and the salary report.
void refreshPayroll(WidgetRef ref, [String? runId]) {
  ref.invalidate(payrollRunsProvider);
  if (runId != null) ref.invalidate(payrollRunProvider(runId));
  ref.invalidate(salaryReportProvider);
}
