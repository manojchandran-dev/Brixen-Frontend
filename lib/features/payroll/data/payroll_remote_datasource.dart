import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/payroll.dart';
import '../domain/piece_pay.dart';
import '../domain/salary_summary.dart';

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

  /// A run key as the API names it: a week's Monday "2026-10-26" →
  /// week_start, a month "2026-10" → month.
  static Map<String, String> _period(String key) =>
      key.length == 10 ? {'week_start': key} : {'month': key};

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

  /// The period's ([month]: "2026-10" or a week's Monday) default working
  /// days (its month less Sundays), and its run
  /// if there is one.
  Future<({int workingDays, String? runId, String? status})> preview(
    String month,
  ) => _call(() async {
    final data = _data(
      await _dio.get(
        ApiEndpoints.payrollPreview,
        queryParameters: _period(month),
      ),
    );
    final run = (data['run'] as Map?)?.cast<String, dynamic>();
    return (
      workingDays: (data['working_days'] as num?)?.toInt() ?? 0,
      runId: run?['id']?.toString(),
      status: run?['status']?.toString(),
    );
  });

  /// Works out the period's ([month]: "2026-10" or a week's Monday)
  /// payslips (again, for a draft).
  Future<PayrollRun> generate(String month, {int? workingDays}) => _call(
    () async => PayrollRun.fromJson(
      _data(
        await _dio.post(
          ApiEndpoints.payrollRuns,
          data: {..._period(month), 'working_days': ?workingDays},
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

  List<PiecePay> _piecePays(Map<String, dynamic> data) => [
    for (final p in (data['items'] as List? ?? const []))
      PiecePay.fromJson((p as Map).cast<String, dynamic>()),
  ];

  /// Piece pays dated [from] to [to] ("YYYY-MM-DD"); [status] narrows to
  /// drafts or confirmed ones.
  Future<List<PiecePay>> piecePays({
    String? from,
    String? to,
    String? status,
  }) => _call(
    () async => _piecePays(
      _data(
        await _dio.get(
          ApiEndpoints.piecePays,
          queryParameters: {'from': ?from, 'to': ?to, 'status': ?status},
        ),
      ),
    ),
  );

  /// [body]: employee_id, work_type_id, pay_date, unit (PIECE / COMBO),
  /// quantity, product_id (combo), notes.
  Future<PiecePay> savePiecePay(Map<String, dynamic> body, {String? id}) =>
      _call(
        () async => PiecePay.fromJson(
          _data(
            id == null
                ? await _dio.post(ApiEndpoints.piecePays, data: body)
                : await _dio.put(ApiEndpoints.piecePay(id), data: body),
          ),
        ),
      );

  Future<void> deletePiecePay(String id) =>
      _call(() => _dio.delete(ApiEndpoints.piecePay(id)));

  /// confirm / reopen / send (email).
  Future<PiecePay> piecePayAction(String id, String action) => _call(
    () async => PiecePay.fromJson(
      _data(await _dio.post(ApiEndpoints.piecePayAction(id, action))),
    ),
  );

  /// Each employee's work and pay so far for a period ([key]: "2026-10" or a
  /// week's Monday).
  Future<SalarySummary> summary(String key) => _call(
    () async => SalarySummary.fromJson(
      _data(
        await _dio.get(
          ApiEndpoints.payrollSummary,
          queryParameters: _period(key),
        ),
      ),
    ),
  );

  /// What sold from [from] to [to] ("YYYY-MM-DD"), by day and product.
  Future<List<SoldLine>> sales({required String from, required String to}) =>
      _call(() async {
        final data = _data(
          await _dio.get(
            ApiEndpoints.payrollSales,
            queryParameters: {'from': from, 'to': to},
          ),
        );
        return [
          for (final s in (data['items'] as List? ?? const []))
            SoldLine.fromJson((s as Map).cast<String, dynamic>()),
        ];
      });

  /// The signed-in employee's confirmed piece pays.
  Future<List<PiecePay>> myPiecePays() => _call(
    () async => _piecePays(_data(await _dio.get(ApiEndpoints.myPiecePays))),
  );

  /// The signed-in employee's payslips.
  Future<List<Payslip>> myPayslips() =>
      _call(() async => _slips(_data(await _dio.get(ApiEndpoints.myPayslips))));
}
