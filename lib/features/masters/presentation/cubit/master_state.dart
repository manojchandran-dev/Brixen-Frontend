import 'package:equatable/equatable.dart';
import '../../domain/entities/master_item.dart';

abstract class MasterState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MasterLoading extends MasterState {}

class MasterLoaded extends MasterState {
  final String typeKey;
  final List<MasterItem> items;
  final String query;

  MasterLoaded({required this.typeKey, required this.items, this.query = ''});

  List<MasterItem> get filtered => query.isEmpty
      ? items
      : items.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList();

  @override
  List<Object?> get props => [typeKey, items, query];
}
