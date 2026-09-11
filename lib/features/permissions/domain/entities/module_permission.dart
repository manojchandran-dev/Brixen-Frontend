import 'package:flutter/material.dart';

enum AccessLevel { none, custom, full }

extension AccessLevelX on AccessLevel {
  String get label => switch (this) {
    AccessLevel.none => 'No Access',
    AccessLevel.custom => 'Custom',
    AccessLevel.full => 'Full Access',
  };

  String get description => switch (this) {
    AccessLevel.none => 'No permissions allowed',
    AccessLevel.custom => 'Choose required permissions',
    AccessLevel.full => 'View, Create, Edit and Delete',
  };

  IconData get icon => switch (this) {
    AccessLevel.none => Icons.shield_outlined,
    AccessLevel.custom => Icons.tune_rounded,
    AccessLevel.full => Icons.verified_user_rounded,
  };

  /// Reverses [label] — used to parse the server's derived `access_level`
  /// string (e.g. "Full Access") back into the enum.
  static AccessLevel fromLabel(String label) => AccessLevel.values.firstWhere(
    (l) => l.label == label,
    orElse: () => AccessLevel.custom,
  );
}

/// One module's (or Master type's) access configuration for a single
/// company owner. Backed by `/api/v1/permissions` — [remoteId] is the
/// saved row's id once one exists (`POST` first time, `PUT` after), or
/// null when no row has been created yet, in which case the module is
/// implicitly Full Access (the server default until a super-admin saves
/// an explicit restriction).
class ModulePermission {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  // Which list section this row belongs to on the permissions screen, e.g.
  // "Modules" for a top-level entry or the parent's name (e.g. "Masters")
  // for a nested one — mirrors whatever grouping the modules API returns.
  final String group;
  final String? remoteId;
  final AccessLevel accessLevel;
  final bool canView;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;

  const ModulePermission({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.group,
    this.remoteId,
    required this.accessLevel,
    required this.canView,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
  });

  factory ModulePermission.full({
    required String key,
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required String group,
  }) => ModulePermission(
    key: key,
    name: name,
    description: description,
    icon: icon,
    color: color,
    group: group,
    accessLevel: AccessLevel.full,
    canView: true,
    canCreate: true,
    canEdit: true,
    canDelete: true,
  );

  ModulePermission copyWith({
    String? remoteId,
    AccessLevel? accessLevel,
    bool? canView,
    bool? canCreate,
    bool? canEdit,
    bool? canDelete,
  }) => ModulePermission(
    key: key,
    name: name,
    description: description,
    icon: icon,
    color: color,
    group: group,
    remoteId: remoteId ?? this.remoteId,
    accessLevel: accessLevel ?? this.accessLevel,
    canView: canView ?? this.canView,
    canCreate: canCreate ?? this.canCreate,
    canEdit: canEdit ?? this.canEdit,
    canDelete: canDelete ?? this.canDelete,
  );

  /// Applies a new access level, snapping the four toggles to match it —
  /// Full turns everything on, No Access turns everything off. Custom
  /// leaves the current toggle values as a starting point for manual edits.
  ModulePermission withAccessLevel(AccessLevel level) {
    switch (level) {
      case AccessLevel.full:
        return copyWith(
          accessLevel: level,
          canView: true,
          canCreate: true,
          canEdit: true,
          canDelete: true,
        );
      case AccessLevel.none:
        return copyWith(
          accessLevel: level,
          canView: false,
          canCreate: false,
          canEdit: false,
          canDelete: false,
        );
      case AccessLevel.custom:
        return copyWith(accessLevel: level);
    }
  }

  /// Short badge text shown on the list row, e.g. "View + Create".
  String get summary {
    if (accessLevel == AccessLevel.full) return 'Full Access';
    if (accessLevel == AccessLevel.none) return 'No Access';
    final on = <String>[
      if (canView) 'View',
      if (canCreate) 'Create',
      if (canEdit) 'Edit',
      if (canDelete) 'Delete',
    ];
    return on.isEmpty ? 'No Access' : on.join(' + ');
  }
}
