import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/company_categories_remote_datasource.dart';
import '../../data/datasources/expense_categories_remote_datasource.dart';
import '../../data/datasources/product_categories_remote_datasource.dart';
import '../../data/datasources/remote_master_datasource.dart';
import '../../data/datasources/units_remote_datasource.dart';
import '../../data/repositories/masters_repository_impl.dart';
import '../../domain/entities/master_item.dart';
import '../../domain/repositories/masters_repository.dart';
import 'master_state.dart';

// Master types backed by a real API — everything else still lives in the
// in-memory `_store` below. Add an entry here for any new type once its
// backend exists; MasterCubit handles the rest generically.
final Map<String, RemoteMasterDatasource> _remoteDatasources = {
  'expenseCategory': expenseCategoriesRemoteDatasource,
  'companyCategory': companyCategoriesRemoteDatasource,
  'productCategory': productCategoriesRemoteDatasource,
  'unit': unitsRemoteDatasource,
};

final masterCubit = MasterCubit(MastersRepositoryImpl(_remoteDatasources));

class MasterCubit extends Cubit<MasterState> {
  MasterCubit(this._repository) : super(MasterLoading());

  final MastersRepository _repository;
  final Map<String, List<MasterItem>> _store = {};
  String _activeType = '';
  String _query = '';

  bool isRemote(String typeKey) => _repository.isRemote(typeKey);

  /// Exposed for the edit form, which needs to fetch a single item fresh
  /// (rather than from the cached list) when the type is remote-backed.
  Future<MasterItem> fetchByIdRemote(String typeKey, String id) =>
      _repository.getById(typeKey, id);

  Future<void> load(String typeKey) async {
    _activeType = typeKey;
    _query = '';
    if (_repository.isRemote(typeKey)) {
      emit(MasterLoading());
      try {
        _store[typeKey] = await _repository.getAll(typeKey);
      } catch (e) {
        emit(MasterError(e.toString()));
        return;
      }
      _emit();
      return;
    }
    _store.putIfAbsent(typeKey, () => []);
    _emit();
  }

  Future<void> add(MasterItem item, {required String companyId}) async {
    if (_repository.isRemote(item.typeKey)) {
      final created = await _repository.create(
        item.typeKey,
        name: item.name,
        description: item.description,
        fullForm: item.fullForm,
        isActive: item.isActive,
        companyId: companyId,
      );
      _store[item.typeKey] = [...(_store[item.typeKey] ?? []), created];
      _emit();
      return;
    }
    _store[item.typeKey]?.add(item);
    _emit();
  }

  Future<void> update(MasterItem updated) async {
    if (_repository.isRemote(updated.typeKey)) {
      final saved = await _repository.update(
        updated.typeKey,
        updated.id,
        name: updated.name,
        description: updated.description,
        fullForm: updated.fullForm,
        isActive: updated.isActive,
      );
      final list = _store[updated.typeKey];
      final i = list?.indexWhere((x) => x.id == saved.id) ?? -1;
      if (i != -1) list![i] = saved;
      _emit();
      return;
    }
    final list = _store[updated.typeKey];
    if (list == null) return;
    final i = list.indexWhere((x) => x.id == updated.id);
    if (i != -1) list[i] = updated;
    _emit();
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> delete(String id) async {
    if (_repository.isRemote(_activeType)) {
      try {
        await _repository.delete(_activeType, id);
      } catch (e) {
        return e.toString();
      }
    }
    _store[_activeType]?.removeWhere((x) => x.id == id);
    _emit();
    return null;
  }

  void search(String q) {
    _query = q;
    _emit();
  }

  /// Returns all active items of a given type (for dropdown use in other forms).
  List<MasterItem> itemsOfType(String typeKey) =>
      (_store[typeKey] ?? []).where((x) => x.isActive).toList();

  /// Unfiltered — includes inactive items too. Used for resolving a
  /// display name for a reference that may point at something no longer
  /// active (e.g. an expense's category/unit).
  List<MasterItem> allItemsOfType(String typeKey) =>
      List.from(_store[typeKey] ?? []);

  /// Returns master menu items assigned to a specific company category.
  List<MasterItem> masterMenusForCategory(String categoryId) =>
      (_store['masterMenu'] ?? [])
          .where((x) => x.isActive && x.assignedCategoryId == categoryId)
          .toList();

  void _emit() => emit(
    MasterLoaded(
      typeKey: _activeType,
      items: List.from(_store[_activeType] ?? []),
      query: _query,
    ),
  );
}
