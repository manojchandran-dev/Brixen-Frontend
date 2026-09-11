import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/purchase.dart';

final purchasesProvider = AsyncNotifierProvider<PurchasesNotifier, List<Purchase>>(
  PurchasesNotifier.new,
);

// No repository layer yet — this feature has no backend datasource at all
// (pure in-memory notifier). Add one only when a real
// purchases_remote_datasource.dart exists to wrap.
class PurchasesNotifier extends AsyncNotifier<List<Purchase>> {
  List<Purchase> _all = [];

  @override
  Future<List<Purchase>> build() async {
    _all = [];
    return _all;
  }

  Future<void> addPurchase(Purchase purchase) async {
    _all = [..._all, purchase];
    state = AsyncData(List.from(_all));
  }

  Future<void> updatePurchase(Purchase updated) async {
    _all = _all.map((p) => p.id == updated.id ? updated : p).toList();
    state = AsyncData(List.from(_all));
  }

  Future<void> deletePurchase(String id) async {
    _all = _all.where((p) => p.id != id).toList();
    state = AsyncData(List.from(_all));
  }
}
