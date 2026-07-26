import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/company.dart';
import 'status_badge.dart';
import '../../../../core/theme/app_colors.dart';

class CompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onView;

  const CompanyCard({
    super.key,
    required this.company,
    this.onDelete,
    this.onToggleStatus,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Initials avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    company.initials,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Company info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company.email,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // 3-dot menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                onSelected: (v) {
                  if (v == 'view')   onView?.call();
                  if (v == 'toggle') onToggleStatus?.call();
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(children: [
                      Icon(Icons.visibility_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 10),
                      Text('View', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(children: [
                      Icon(company.isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 16, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 10),
                      Text(company.isActive ? 'Mark Inactive' : 'Mark Active',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 10),
                      const Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(isActive: company.isActive),
              Text(
                'Created at\n${DateFormat('MMM dd, yyyy').format(company.createdAt)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
