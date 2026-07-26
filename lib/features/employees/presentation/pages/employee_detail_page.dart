import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/employee.dart';
import '../providers/employees_provider.dart';

class EmployeeDetailPage extends ConsumerWidget {
  final Employee employee;
  const EmployeeDetailPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(employee.status);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Theme.of(context).dividerColor)),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: isDark ? AppColors.silverGradient : null, color: isDark ? null : AppColors.lightTextPrimary, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))]),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(employee.fullName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
          Text(employee.employeeCode, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createEmployee, extra: employee),
            child: Container(margin: const EdgeInsets.fromLTRB(0, 8, 8, 8), width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accentIndigo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3))), child: Icon(Icons.edit_outlined, size: 18, color: AppColors.accentIndigo)),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(margin: const EdgeInsets.fromLTRB(0, 8, 16, 8), width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3))), child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // Hero card
          _SectionCard(isDark: isDark, child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.accentEmerald.withValues(alpha: 0.12), shape: BoxShape.circle, border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.35))),
              child: Center(child: Text(employee.firstName.isNotEmpty ? employee.firstName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accentEmerald))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(employee.fullName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
              if (employee.designation != null) ...[
                const SizedBox(height: 2),
                Text(employee.designation!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
              if (employee.department != null) ...[
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.apartment_outlined, size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(employee.department!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ],
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.35))),
              child: Text(employee.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ])),
          const SizedBox(height: 14),

          // Personal info
          _SectionTitle('Personal Information'),
          const SizedBox(height: 8),
          _SectionCard(isDark: isDark, child: Column(children: [
            if (employee.gender != null) ...[_DetailRow(icon: Icons.wc_rounded, label: 'Gender', value: employee.gender!), _DividerLine()],
            if (employee.dateOfBirth != null) ...[_DetailRow(icon: Icons.cake_outlined, label: 'Date of Birth', value: DateFormat('dd MMM yyyy').format(employee.dateOfBirth!)), _DividerLine()],
            if (employee.email != null) ...[_DetailRow(icon: Icons.mail_outline_rounded, label: 'Email', value: employee.email!), _DividerLine()],
            if (employee.phone != null) ...[_DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: employee.phone!), if (employee.address != null) _DividerLine()],
            if (employee.address != null) _DetailRow(icon: Icons.location_on_outlined, label: 'Address', value: employee.address!),
          ])),
          const SizedBox(height: 14),

          // Employment info
          _SectionTitle('Employment Details'),
          const SizedBox(height: 8),
          _SectionCard(isDark: isDark, child: Column(children: [
            if (employee.joiningDate != null) ...[_DetailRow(icon: Icons.calendar_today_outlined, label: 'Joining Date', value: DateFormat('dd MMM yyyy').format(employee.joiningDate!)), _DividerLine()],
            if (employee.employmentType != null) ...[_DetailRow(icon: Icons.work_outline_rounded, label: 'Employment Type', value: employee.employmentType!), _DividerLine()],
            if (employee.managerName != null) ...[_DetailRow(icon: Icons.supervisor_account_outlined, label: 'Manager', value: employee.managerName!), if (employee.salary != null) _DividerLine()],
            if (employee.salary != null) _DetailRow(icon: Icons.currency_rupee_rounded, label: 'Salary', value: employee.salary!.toStringAsFixed(2)),
          ])),
          const SizedBox(height: 14),

          // Banking & IDs
          if (employee.panNumber != null || employee.aadhaarNumber != null || employee.bankName != null || employee.accountNumber != null || employee.ifscCode != null) ...[
            _SectionTitle('Banking & Government IDs'),
            const SizedBox(height: 8),
            _SectionCard(isDark: isDark, child: Column(children: [
              if (employee.panNumber != null) ...[_DetailRow(icon: Icons.badge_outlined, label: 'PAN', value: employee.panNumber!), _DividerLine()],
              if (employee.aadhaarNumber != null) ...[_DetailRow(icon: Icons.credit_card_outlined, label: 'Aadhaar', value: employee.aadhaarNumber!), _DividerLine()],
              if (employee.bankName != null) ...[_DetailRow(icon: Icons.account_balance_outlined, label: 'Bank', value: employee.bankName!), _DividerLine()],
              if (employee.accountNumber != null) ...[_DetailRow(icon: Icons.numbers_rounded, label: 'Account No.', value: employee.accountNumber!), if (employee.ifscCode != null) _DividerLine()],
              if (employee.ifscCode != null) _DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'IFSC', value: employee.ifscCode!),
            ])),
            const SizedBox(height: 14),
          ],

          // Emergency contact
          if (employee.emergencyContactName != null || employee.emergencyContactPhone != null) ...[
            _SectionTitle('Emergency Contact'),
            const SizedBox(height: 8),
            _SectionCard(isDark: isDark, child: Column(children: [
              if (employee.emergencyContactName != null) ...[_DetailRow(icon: Icons.contact_emergency_outlined, label: 'Name', value: employee.emergencyContactName!), if (employee.emergencyContactPhone != null) _DividerLine()],
              if (employee.emergencyContactPhone != null) _DetailRow(icon: Icons.phone_in_talk_outlined, label: 'Phone', value: employee.emergencyContactPhone!),
            ])),
            const SizedBox(height: 14),
          ],

          _SectionCard(isDark: isDark, child: _DetailRow(icon: Icons.calendar_today_outlined, label: 'Created', value: DateFormat('dd MMM yyyy, hh:mm a').format(employee.createdAt))),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active': return AppColors.accentEmerald;
      case 'Inactive': return AppColors.accentRose;
      default: return AppColors.accentGold;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Employee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text('Delete "${employee.fullName}"? This cannot be undone.', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant))),
          TextButton(
            onPressed: () {
              ref.read(employeesProvider.notifier).deleteEmployee(employee.id);
              Navigator.pop(context);
              context.go(AppRouter.employees);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.4));
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, size: 15, color: cs.onSurfaceVariant),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      Expanded(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface))),
    ]);
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Theme.of(context).dividerColor));
}
