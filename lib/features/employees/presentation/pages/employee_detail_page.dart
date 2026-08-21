import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/action_sheet.dart';
import '../../domain/entities/employee.dart';
import '../providers/employees_provider.dart';

class EmployeeDetailPage extends ConsumerWidget {
  final Employee employee;
  const EmployeeDetailPage({super.key, required this.employee});

  Color _statusColor(String status) {
    switch (status) {
      case 'Active': return AppColors.positive;
      case 'Inactive': return AppColors.ink;
      default: return AppColors.brandLight;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Employee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text('Delete "${employee.fullName}"? This cannot be undone.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(employeesProvider.notifier).deleteEmployee(employee.id);
                if (context.mounted) context.go(AppRouter.employees);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.ink),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static const _statuses = ['Active', 'Inactive', 'On Leave'];

  void _openStatusPicker(BuildContext context, WidgetRef ref) {
    showActionSheet(
      context,
      title: 'Change Status',
      subtitle: employee.fullName,
      items: _statuses.map((s) => ActionSheetItem(
        icon: Icons.circle,
        label: s,
        color: _statusColor(s),
        selected: s == employee.status,
        onTap: () async {
          if (s == employee.status) return;
          try {
            await ref.read(employeesProvider.notifier).updateEmployee(employee.copyWith(status: s));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()), backgroundColor: AppColors.ink),
              );
            }
          }
        },
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(employee.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 40, height: 40,
            margin: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: AppColors.white.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(-2, -2)),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Employees', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textHint),
              Flexible(child: Text(employee.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink))),
            ]),
          ),
          Text(employee.employeeCode, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createEmployee, extra: employee),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.white),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(
              width: 38, height: 38,
              margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── Profile hero card ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 8, offset: const Offset(-3, -3)),
              ],
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 64, height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Text(
                    employee.fullName.trim().isNotEmpty ? employee.fullName.trim()[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(employee.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (employee.designation != null) ...[
                    const SizedBox(height: 3),
                    Text(employee.designation!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                  if (employee.department != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.apartment_rounded, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(employee.department!, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ]),
                  ],
                ])),
                GestureDetector(
                  onTap: () => _openStatusPicker(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(employee.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
                      const SizedBox(width: 3),
                      const Icon(Icons.sync_alt_rounded, size: 12, color: AppColors.white),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _MiniStat(label: 'Code', value: employee.employeeCode)),
                  Expanded(
                    child: _MiniStat(
                      label: 'Joined',
                      value: employee.joiningDate != null ? DateFormat('dd MMM yyyy').format(employee.joiningDate!) : '—',
                    ),
                  ),
                  Expanded(child: _MiniStat(label: 'Type', value: employee.employmentType ?? '—')),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Details — shown directly, no tabs ─────────────────────
          _SectionTitle('Personal Information', icon: Icons.person_rounded, color: AppColors.brand),
          const SizedBox(height: 10),
          _SectionCard(child: Column(children: [
            if (employee.gender != null) ...[_DetailRow(icon: Icons.wc_rounded, label: 'Gender', value: employee.gender!, accentColor: AppColors.brand), _DividerLine()],
            if (employee.dateOfBirth != null) ...[_DetailRow(icon: Icons.cake_rounded, label: 'Date of Birth', value: DateFormat('dd MMM yyyy').format(employee.dateOfBirth!), accentColor: AppColors.positive), _DividerLine()],
            if (employee.email != null) ...[_DetailRow(icon: Icons.mail_rounded, label: 'Email', value: employee.email!, accentColor: AppColors.brand), _DividerLine()],
            if (employee.phone != null) ...[_DetailRow(icon: Icons.phone_rounded, label: 'Phone', value: employee.phone!, accentColor: AppColors.positive), if (employee.address != null) _DividerLine()],
            if (employee.address != null) _DetailRow(icon: Icons.location_on_rounded, label: 'Address', value: employee.address!, accentColor: AppColors.brand),
          ])),
          const SizedBox(height: 18),

          _SectionTitle('Employment Details', icon: Icons.work_rounded, color: AppColors.positive),
          const SizedBox(height: 10),
          _SectionCard(child: Column(children: [
            if (employee.joiningDate != null) ...[_DetailRow(icon: Icons.calendar_month_rounded, label: 'Joining Date', value: DateFormat('dd MMM yyyy').format(employee.joiningDate!), accentColor: AppColors.brand), _DividerLine()],
            if (employee.employmentType != null) ...[_DetailRow(icon: Icons.work_rounded, label: 'Employment Type', value: employee.employmentType!, accentColor: AppColors.positive), _DividerLine()],
            if (employee.managerName != null) ...[_DetailRow(icon: Icons.supervisor_account_rounded, label: 'Manager', value: employee.managerName!, accentColor: AppColors.brand), if (employee.salary != null) _DividerLine()],
            if (employee.salary != null) _DetailRow(icon: Icons.currency_rupee_rounded, label: 'Salary', value: employee.salary!.toStringAsFixed(2), accentColor: AppColors.positive),
          ])),
          const SizedBox(height: 18),

          if (employee.panNumber != null || employee.aadhaarNumber != null || employee.bankName != null || employee.accountNumber != null || employee.ifscCode != null) ...[
            _SectionTitle('Banking & Government IDs', icon: Icons.account_balance_rounded, color: AppColors.brandDeep),
            const SizedBox(height: 10),
            _SectionCard(child: Column(children: [
              if (employee.panNumber != null) ...[_DetailRow(icon: Icons.badge_rounded, label: 'PAN', value: employee.panNumber!, accentColor: AppColors.brand), _DividerLine()],
              if (employee.aadhaarNumber != null) ...[_DetailRow(icon: Icons.credit_card_rounded, label: 'Aadhaar', value: employee.aadhaarNumber!, accentColor: AppColors.positive), _DividerLine()],
              if (employee.bankName != null) ...[_DetailRow(icon: Icons.account_balance_rounded, label: 'Bank', value: employee.bankName!, accentColor: AppColors.brand), _DividerLine()],
              if (employee.accountNumber != null) ...[_DetailRow(icon: Icons.numbers_rounded, label: 'Account No.', value: employee.accountNumber!, accentColor: AppColors.positive), if (employee.ifscCode != null) _DividerLine()],
              if (employee.ifscCode != null) _DetailRow(icon: Icons.account_balance_wallet_rounded, label: 'IFSC', value: employee.ifscCode!, accentColor: AppColors.brand),
            ])),
            const SizedBox(height: 18),
          ],

          if (employee.emergencyContactName != null || employee.emergencyContactPhone != null) ...[
            _SectionTitle('Emergency Contact', icon: Icons.contact_emergency_rounded, color: AppColors.ink),
            const SizedBox(height: 10),
            _SectionCard(child: Column(children: [
              if (employee.emergencyContactName != null) ...[_DetailRow(icon: Icons.contact_emergency_rounded, label: 'Name', value: employee.emergencyContactName!, accentColor: AppColors.brand), if (employee.emergencyContactPhone != null) _DividerLine()],
              if (employee.emergencyContactPhone != null) _DetailRow(icon: Icons.phone_in_talk_rounded, label: 'Phone', value: employee.emergencyContactPhone!, accentColor: AppColors.positive),
            ])),
            const SizedBox(height: 18),
          ],

          _SectionCard(child: _DetailRow(icon: Icons.history_rounded, label: 'Created', value: DateFormat('dd MMM yyyy, hh:mm a').format(employee.createdAt), accentColor: AppColors.brandLight)),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textHint)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionTitle(this.title, {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 22, height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 12, color: color),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
    ]);
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-3, -3)),
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accentColor;
  const _DetailRow({required this.icon, required this.label, required this.value, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentColor, accentColor.withValues(alpha: 0.75)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, size: 16, color: AppColors.white),
      ),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textHint)),
      Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink))),
    ]);
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.border));
}
