import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../employees/data/models/employee_model.dart';
import '../../employees/domain/entities/employee.dart';
import '../domain/attendance.dart';

final attendanceDatasourceProvider = Provider<AttendanceRemoteDatasource>(
  (ref) => AttendanceRemoteDatasource(ref.read(dioProvider)),
);

/// The attendance API: an admin's per-day records (`/attendance`), and an
/// employee login's own data (`/me/...`).
class AttendanceRemoteDatasource {
  final Dio _dio;
  const AttendanceRemoteDatasource(this._dio);

  Map<String, dynamic> _data(Response resp) =>
      ((resp.data is Map ? resp.data['data'] : null) ?? resp.data)
          as Map<String, dynamic>;

  /// One day's records ([date] "YYYY-MM-DD"; null = today in the company's
  /// zone), optionally narrowed by [search] (name or code) and [kind].
  Future<AttendanceList> list({
    String? date,
    String? search,
    String? kind,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.attendance,
        queryParameters: {
          'date': ?date,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          'kind': ?kind,
        },
      );
      return AttendanceList.fromJson(_data(resp));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// [body]: employee_id, work_date, and shifts [{units}] or pieces
  /// [{work_type_id, quantity}], notes.
  Future<AttendanceRecord> create(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post(ApiEndpoints.attendance, data: body);
      return AttendanceRecord.fromJson(_data(resp));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Replaces the day's shifts or pieces (and notes).
  Future<AttendanceRecord> update(String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.put(ApiEndpoints.attendanceById(id), data: body);
      return AttendanceRecord.fromJson(_data(resp));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.attendanceById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// The signed-in employee, their company's name and time zone.
  Future<({Employee employee, String? companyName, String? timezone})>
  myEmployee() async {
    try {
      final data = _data(await _dio.get(ApiEndpoints.myEmployee));
      return (
        employee: EmployeeModel.fromJson(data) as Employee,
        companyName: data['company_name']?.toString(),
        timezone: data['timezone']?.toString(),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// The signed-in employee's days from [from] to [to] ("YYYY-MM-DD"; null
  /// = this month so far).
  Future<MyAttendance> myAttendance({String? from, String? to}) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.myAttendance,
        queryParameters: {'from': ?from, 'to': ?to},
      );
      return MyAttendance.fromJson(_data(resp));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
