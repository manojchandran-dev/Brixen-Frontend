import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../domain/entities/master_type.dart';
import '../widgets/master_type_body.dart';

enum _Mode { list, create, edit }

/// A directly-linkable route for one master type (`/masters/...`), additive
/// alongside the existing Companies → Menu → Masters in-page drill-down —
/// both reach the same [MasterCubit] state, neither replaces the other.
class MasterCategoryPage extends StatefulWidget {
  final String typeKey;
  const MasterCategoryPage({super.key, required this.typeKey});

  @override
  State<MasterCategoryPage> createState() => _MasterCategoryPageState();
}

class _MasterCategoryPageState extends State<MasterCategoryPage> {
  _Mode _mode = _Mode.list;
  String? _editId;

  void _goList() => setState(() {
        _mode = _Mode.list;
        _editId = null;
      });
  void _goCreate() => setState(() {
        _mode = _Mode.create;
        _editId = null;
      });
  void _goEdit(String id) => setState(() {
        _mode = _Mode.edit;
        _editId = id;
      });

  @override
  Widget build(BuildContext context) {
    final typeCfg = masterTypeFor(widget.typeKey);
    final isForm = _mode != _Mode.list;
    final formTitle = switch (_mode) {
      _Mode.create => 'Add ${typeCfg?.name ?? 'Item'}',
      _Mode.edit => 'Edit ${typeCfg?.name ?? 'Item'}',
      _Mode.list => '',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isForm ? null : const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isForm
            ? GestureDetector(
                onTap: _goList,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
              )
            : Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Icon(Icons.menu_rounded, size: 20, color: AppColors.ink),
                ),
              ),
        title: isForm
            ? Text(
                formTitle,
                style: TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w700),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text('Masters', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textHint),
                    ),
                    Text(
                      typeCfg?.name ?? 'Items',
                      style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
        actions: [
          if (!isForm)
            GestureDetector(
              onTap: _goCreate,
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.accentGradient(AppColors.brand)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.add_rounded, size: 20, color: AppColors.white),
              ),
            ),
        ],
      ),
      body: isForm
          ? MasterFormBody(typeKey: widget.typeKey, editId: _editId, onSaved: _goList)
          : MasterItemsBody(typeKey: widget.typeKey, onEdit: _goEdit),
    );
  }
}
