import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/company_category.dart';
import 'company_category_state.dart';

final companyCategoryCubit = CompanyCategoryCubit();

class CompanyCategoryCubit extends Cubit<CompanyCategoryState> {
  CompanyCategoryCubit() : super(CompanyCategoryLoading());

  final List<CompanyCategory> _items = [];

  void load() {
    if (_items.isEmpty) {
      _items.addAll([
        CompanyCategory(id: '1', name: 'Technology', description: 'Tech companies', isActive: true, createdAt: DateTime.now()),
        CompanyCategory(id: '2', name: 'Healthcare', description: 'Medical & health', isActive: true, createdAt: DateTime.now()),
      ]);
    }
    _emit();
  }

  void add(CompanyCategory category) {
    _items.add(category);
    _emit();
  }

  void update(CompanyCategory updated) {
    final i = _items.indexWhere((c) => c.id == updated.id);
    if (i != -1) _items[i] = updated;
    _emit();
  }

  void toggleStatus(String id) {
    final i = _items.indexWhere((c) => c.id == id);
    if (i != -1) _items[i] = _items[i].copyWith(isActive: !_items[i].isActive);
    _emit();
  }

  void delete(String id) {
    _items.removeWhere((c) => c.id == id);
    _emit();
  }

  void search(String q) => _emit(query: q);

  void _emit({String query = ''}) =>
      emit(CompanyCategoryLoaded(items: List.from(_items), query: query));
}
