import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/payroll.dart';

final payrollDatasourceProvider = Provider<PayrollRemoteDatasource>(
  (ref) => PayrollRemoteDatasource(ref.read(dioProvider)),
);

/// Salary generation (`/payroll`, part of Employees) and an employee login's
/// own payslips (`/me/payslips`).
class PayrollRemoteDatasource {
  final Dio _dio;
  const PayrollRemoteDatasource(this._dio);

  Map<String, dynamic> _data(Response resp) =>
      ((resp.data is Map ? resp.data['data'] : null) ?? resp.data)
          as Map<String, dynamic>;

  Future<T> _call<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  List<Payslip> _slips(Map<String, dynamic> data) => [
    for (final p in (data['items'] as List? ?? const []))
      Payslip.fromJson((p as Map).cast<String, dynamic>()),
  ];

  Future<List<PayrollRun>> runs() => _call(() async {
    final data = _data(await _dio.get(ApiEndpoints.payrollRuns));
    return [
      for (final r in (data['items'] as List? ?? const []))
        PayrollRun.fromJson((r as Map).cast<String, dynamic>()),
    ];
  });

  Future<PayrollRun> run(String id) => _call(
    () async =>
        PayrollRun.fromJson(_data(await _dio.get(ApiEndpoints.payrollRun(id)))),
  );

  /// [month]'s default working days (the month less Sundays), and its run
  /// if there is one.
  Future<({int workingDays, String? runId, String? status})> preview(
    String month,
  ) => _call(() async {
    final data = _data(
      await _dio.get(
        ApiEndpoints.payrollPreview,
        queryParameters: {'month': month},
      ),
    );
    final run = (data['run'] as Map?)?.cast<String, dynamic>();
    return (
      workingDays: (data['working_days'] as num?)?.toInt() ?? 0,
      runId: run?['id']?.toString(),
      status: run?['status']?.toString(),
    );
  });

  /// Works out [month]'s payslips (again, for a draft).
  Future<PayrollRun> generate(String month, {int? workingDays}) => _call(
    () async => PayrollRun.fromJson(
      _data(
        await _dio.post(
          ApiEndpoints.payrollRuns,
          data: {'month': month, 'working_days': ?workingDays},
        ),
      ),
    ),
  );

  Future<PayrollRun> finalize(String id) => _call(
    () async => PayrollRun.fromJson(
      _data(await _dio.post(ApiEndpoints.payrollRunAction(id, 'finalize'))),
    ),
  );

  Future<PayrollRun> reopen(String id) => _call(
    () async => PayrollRun.fromJson(
      _data(await _dio.post(ApiEndpoints.payrollRunAction(id, 'reopen'))),
    ),
  );

  Future<void> deleteRun(String id) =>
      _call(() => _dio.delete(ApiEndpoints.payrollRun(id)));

  /// Emails the run's payslips (or just [payslipIds]).
  Future<SendResult> send(String runId, {List<String>? payslipIds}) => _call(
    () async => SendResult.fromJson(
      _data(
        await _dio.post(
          ApiEndpoints.payrollRunAction(runId, 'send'),
          data: {'payslip_ids': ?payslipIds},
        ),
      ),
    ),
  );

  Future<Payslip> updatePayslip(
    String id, {
    required double additions,
    required double deductions,
    String? notes,
  }) => _call(
    () async => Payslip.fromJson(
      _data(
        await _dio.put(
          ApiEndpoints.payslip(id),
          data: {
            'additions': additions,
            'deductions': deductions,
            'notes': notes ?? '',
          },
        ),
      ),
    ),
  );

  /// Finalized payslips, for the salary report.
  Future<List<Payslip>> payslips() =>
      _call(() async => _slips(_data(await _dio.get(ApiEndpoints.payslips))));

  /// The signed-in employee's payslips.
  Future<List<Payslip>> myPayslips() =>
      _call(() async => _slips(_data(await _dio.get(ApiEndpoints.myPayslips))));
}
