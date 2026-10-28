import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payroll_remote_datasource.dart';
import '../domain/payroll.dart';
import '../domain/piece_pay.dart';
import '../domain/salary_summary.dart';

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
  ref.invalidate(salarySummaryProvider);
}

/// A month's ("YYYY-MM") piece pays, drafts and confirmed.
final piecePaysMonthProvider = FutureProvider.autoDispose
    .family<List<PiecePay>, String>((ref, month) {
      final y = int.parse(month.substring(0, 4));
      final m = int.parse(month.substring(5, 7));
      final last = DateTime(y, m + 1, 0).day.toString().padLeft(2, '0');
      return ref
          .read(payrollDatasourceProvider)
          .piecePays(from: '$month-01', to: '$month-$last');
    });

/// Confirmed piece pays, for the salary report.
final piecePayReportProvider = FutureProvider.autoDispose<List<PiecePay>>(
  (ref) =>
      ref.read(payrollDatasourceProvider).piecePays(status: PiecePay.confirmed),
);

/// The signed-in employee's confirmed piece pays.
final myPiecePaysProvider = FutureProvider.autoDispose<List<PiecePay>>(
  (ref) => ref.read(payrollDatasourceProvider).myPiecePays(),
);

/// After a piece pay changes: the month lists and the salary report.
void refreshPiecePays(WidgetRef ref) {
  ref.invalidate(piecePaysMonthProvider);
  ref.invalidate(piecePayReportProvider);
  ref.invalidate(salarySummaryProvider);
}

/// Each employee's work and pay so far for a period ("2026-10" or a week's
/// Monday).
final salarySummaryProvider = FutureProvider.autoDispose
    .family<SalarySummary, String>(
      (ref, key) => ref.read(payrollDatasourceProvider).summary(key),
    );

/// A month's ("YYYY-MM") sales by day and product, for entering piece pay.
final salesByDayProvider = FutureProvider.autoDispose
    .family<List<SoldLine>, String>((ref, month) {
      final y = int.parse(month.substring(0, 4));
      final m = int.parse(month.substring(5, 7));
      final last = DateTime(y, m + 1, 0).day.toString().padLeft(2, '0');
      return ref
          .read(payrollDatasourceProvider)
          .sales(from: '$month-01', to: '$month-$last');
    });
