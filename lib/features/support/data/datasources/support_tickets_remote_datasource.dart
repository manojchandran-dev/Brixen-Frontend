import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/support_ticket_model.dart';

final supportTicketsRemoteDatasourceProvider =
    Provider<SupportTicketsRemoteDatasource>((ref) {
      return SupportTicketsRemoteDatasource(ref.read(dioProvider));
    });

class SupportTicketsRemoteDatasource {
  final Dio _dio;
  const SupportTicketsRemoteDatasource(this._dio);

  SupportTicketModel _ticket(Response resp) {
    final data = resp.data['data'] ?? resp.data;
    return SupportTicketModel.fromJson(data as Map<String, dynamic>);
  }

  /// Search and filters are applied by the server. Values are the enum
  /// names (e.g. `inProgress`, `featureRequest`); null = All.
  Future<List<SupportTicketModel>> getAll({
    String? search,
    String? status,
    String? priority,
    String? category,
    String? companyId,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.supportTickets,
        queryParameters: {
          'page': 1,
          'limit': 100,
          if (search != null && search.isNotEmpty) 'search': search,
          'status': ?status,
          'priority': ?priority,
          'category': ?category,
          'company_id': ?companyId,
        },
      );
      final data = resp.data['data'] ?? resp.data;
      final list = data is List ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// The list may not carry messages — this returns the full ticket with them.
  Future<SupportTicketModel> getById(String id) async {
    try {
      return _ticket(await _dio.get(ApiEndpoints.supportTicketById(id)));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SupportTicketModel> create(SupportTicketModel t) async {
    try {
      return _ticket(
        await _dio.post(
          ApiEndpoints.supportTickets,
          data: {
            'subject': t.subject,
            'description': t.description,
            'category': t.category.name,
            'priority': t.priority.name,
          },
        ),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SupportTicketModel> addMessage(String ticketId, String text) async {
    try {
      return _ticket(
        await _dio.post(
          ApiEndpoints.supportTicketMessages(ticketId),
          data: {'text': text},
        ),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SupportTicketModel> updateStatus(
    String ticketId,
    String status,
  ) async {
    try {
      return _ticket(
        await _dio.put(
          ApiEndpoints.supportTicketStatus(ticketId),
          data: {'status': status},
        ),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SupportTicketModel> assign(String ticketId, String assignee) async {
    try {
      return _ticket(
        await _dio.put(
          ApiEndpoints.supportTicketAssign(ticketId),
          data: {'assigned_to': assignee},
        ),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
