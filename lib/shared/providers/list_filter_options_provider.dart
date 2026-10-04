import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

/// `GET {listPath}/filters` — the distinct values a company's list has
/// (statuses, departments, payment types, categories…), for its filter
/// sheet. Empty on failure: the page falls back to the loaded list.
final listFilterOptionsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, listPath) async {
      try {
        final resp = await ref.read(dioProvider).get('$listPath/filters');
        final data = resp.data is Map ? (resp.data['data'] ?? resp.data) : null;
        return data is Map ? Map<String, dynamic>.from(data) : const {};
      } catch (_) {
        return const {};
      }
    });

/// Options for [key] from a /filters response: plain values → (value,
/// value); `{id, name}` categories → (id, name).
List<(Object, String)> serverOptions(Map<String, dynamic> filters, String key) {
  final raw = filters[key];
  if (raw is! List) return const [];
  return [
    for (final v in raw)
      if (v is Map)
        ('${v['id']}', '${v['name'] ?? v['id']}')
      else if (v != null && '$v'.trim().isNotEmpty)
        ('$v', '$v'),
  ];
}
