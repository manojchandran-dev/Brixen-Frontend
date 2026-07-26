import 'package:flutter/material.dart';

class MasterTypeConfig {
  final String key;
  final String name;
  final IconData icon;
  // true = form shows "Assign to Company Category" dropdown
  final bool hasParentAssignment;

  const MasterTypeConfig(
    this.key,
    this.name,
    this.icon, {
    this.hasParentAssignment = false,
  });
}

const kMasterTypes = <MasterTypeConfig>[
  MasterTypeConfig('companyCategory', 'Company Category', Icons.category_outlined),
  MasterTypeConfig('masterMenu',      'Master Menu',      Icons.add_to_queue_outlined, hasParentAssignment: true),
  MasterTypeConfig('expenseCategory', 'Expense Category', Icons.receipt_outlined),
];

MasterTypeConfig? masterTypeFor(String key) {
  try {
    return kMasterTypes.firstWhere((t) => t.key == key);
  } catch (_) {
    return null;
  }
}
