import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sale.dart';

final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(
  SalesNotifier.new,
);

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  List<Sale> _all = [];

  @override
  Future<List<Sale>> build() async {
    // TODO: load from API
    _all = [];
    return _all;
  }

  Future<void> addSale(Sale sale) async {
    _all = [..._all, sale];
    state = AsyncData(List.from(_all));
  }

  Future<void> updateSale(Sale updated) async {
    _all = _all.map((s) => s.id == updated.id ? updated : s).toList();
    state = AsyncData(List.from(_all));
  }

  Future<void> deleteSale(String id) async {
    _all = _all.where((s) => s.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
