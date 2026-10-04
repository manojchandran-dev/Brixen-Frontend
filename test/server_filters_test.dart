import 'dart:convert';
import 'dart:typed_data';

import 'package:brixen/core/network/api_client.dart';
import 'package:brixen/shared/providers/list_filter_options_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves [total] rows, 100 a page, like the API; records each request.
class _PagedAdapter implements HttpClientAdapter {
  final int total;
  final requests = <Map<String, dynamic>>[];
  _PagedAdapter(this.total);

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(o.queryParameters);
    final page = o.queryParameters['page'] as int;
    final limit = o.queryParameters['limit'] as int;
    final start = (page - 1) * limit;
    final items = [
      for (var i = start; i < total && i < start + limit; i++) {'id': '$i'},
    ];
    return ResponseBody.fromString(
      jsonEncode({
        'data': {'items': items},
        'meta': {'page': page, 'limit': limit, 'total': total, 'pages': (total / limit).ceil()},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('fetchAllPages walks every page (100 max) and keeps the filters', () async {
    final adapter = _PagedAdapter(230);
    final dio = Dio()..httpClientAdapter = adapter;
    final rows = await fetchAllPages(dio, '/employees', {'status': 'Active'});
    expect(rows, hasLength(230));
    expect(adapter.requests, hasLength(3));
    expect(adapter.requests.every((q) => q['limit'] == 100), isTrue);
    expect(adapter.requests.every((q) => q['status'] == 'Active'), isTrue);
  });

  test('fetchAllPages: one request when everything fits', () async {
    final adapter = _PagedAdapter(7);
    final dio = Dio()..httpClientAdapter = adapter;
    expect(await fetchAllPages(dio, '/sales', const {}), hasLength(7));
    expect(adapter.requests, hasLength(1));
  });

  test('serverOptions: plain values and {id, name} categories', () {
    final f = {
      'status': ['Active', 'On Leave'],
      'categories': [
        {'id': 'c1', 'name': 'Men Shirts'},
      ],
    };
    expect(serverOptions(f, 'status'), [('Active', 'Active'), ('On Leave', 'On Leave')]);
    expect(serverOptions(f, 'categories'), [('c1', 'Men Shirts')]);
    expect(serverOptions(f, 'missing'), isEmpty);
  });
}
