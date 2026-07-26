import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/master_item.dart';
import 'master_state.dart';

final masterCubit = MasterCubit();

class MasterCubit extends Cubit<MasterState> {
  MasterCubit() : super(MasterLoading());

  final Map<String, List<MasterItem>> _store = {};
  String _activeType = '';
  String _query = '';

  void load(String typeKey) {
    _activeType = typeKey;
    _query = '';
    _store.putIfAbsent(typeKey, () => []);
    _emit();
  }

  void add(MasterItem item) {
    _store[item.typeKey]?.add(item);
    _emit();
  }

  void update(MasterItem updated) {
    final list = _store[updated.typeKey];
    if (list == null) return;
    final i = list.indexWhere((x) => x.id == updated.id);
    if (i != -1) list[i] = updated;
    _emit();
  }

  void toggleStatus(String id) {
    final list = _store[_activeType];
    if (list == null) return;
    final i = list.indexWhere((x) => x.id == id);
    if (i != -1) list[i] = list[i].copyWith(isActive: !list[i].isActive);
    _emit();
  }

  void delete(String id) {
    _store[_activeType]?.removeWhere((x) => x.id == id);
    _emit();
  }

  void search(String q) {
    _query = q;
    _emit();
  }

  /// Returns all active items of a given type (for dropdown use in other forms).
  List<MasterItem> itemsOfType(String typeKey) =>
      (_store[typeKey] ?? []).where((x) => x.isActive).toList();

  /// Returns master menu items assigned to a specific company category.
  List<MasterItem> masterMenusForCategory(String categoryId) =>
      (_store['masterMenu'] ?? [])
          .where((x) => x.isActive && x.assignedCategoryId == categoryId)
          .toList();

  void _emit() => emit(MasterLoaded(
    typeKey: _activeType,
    items: List.from(_store[_activeType] ?? []),
    query: _query,
  ));
}
