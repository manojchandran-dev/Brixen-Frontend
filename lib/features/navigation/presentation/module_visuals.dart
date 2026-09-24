import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Icon + colour for a menu module, keyed by name. `GET /api/v1/modules`
/// only carries id/name/description/parent_id/children — no presentation
/// info — so this is the one client-side lookup every screen that renders
/// modules (the drawer, the Permissions screens) shares, with a neutral
/// fallback for any module name it doesn't recognise yet.
class ModuleVisual {
  final IconData icon;
  final Color color;
  const ModuleVisual(this.icon, this.color);
}

ModuleVisual moduleVisualFor(String name) {
  final key = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  switch (key) {
    case 'companies':
      return const ModuleVisual(Icons.business_rounded, AppColors.brand);
    case 'permissions':
      return const ModuleVisual(
        Icons.admin_panel_settings_outlined,
        AppColors.brandDeep,
      );
    case 'employees':
      return const ModuleVisual(Icons.badge_rounded, AppColors.positive);
    case 'sales':
      return const ModuleVisual(
        Icons.receipt_long_rounded,
        AppColors.brandDeep,
      );
    case 'purchases':
      return const ModuleVisual(
        Icons.shopping_cart_outlined,
        AppColors.brandLight,
      );
    case 'customers':
      return const ModuleVisual(
        Icons.people_alt_rounded,
        AppColors.brandLight,
      );
    case 'expenses':
      return const ModuleVisual(
        Icons.receipt_outlined,
        AppColors.brandBlack,
      );
    case 'products':
      return const ModuleVisual(Icons.checkroom_rounded, AppColors.brand);
    case 'companycategory':
      return const ModuleVisual(Icons.apartment_rounded, AppColors.brand);
    case 'expensecategory':
      return const ModuleVisual(Icons.sell_rounded, AppColors.positive);
    case 'units':
    case 'unit':
      return const ModuleVisual(
        Icons.straighten_rounded,
        AppColors.brandDeep,
      );
    case 'productcategory':
      return const ModuleVisual(
        Icons.checkroom_outlined,
        AppColors.brandLight,
      );
    case 'notifications':
    case 'pushnotifications':
      return const ModuleVisual(Icons.notifications_active_rounded, AppColors.brand);
    case 'announcements':
      return const ModuleVisual(Icons.campaign_rounded, AppColors.brandDeep);
    case 'chat':
    case 'chatbot':
      return const ModuleVisual(Icons.chat_bubble_outline_rounded, AppColors.brandDeep);
    case 'support':
    case 'supportticket':
    case 'supporttickets':
      return const ModuleVisual(Icons.support_agent_rounded, AppColors.positive);
    default:
      return ModuleVisual(Icons.widgets_outlined, AppColors.textHint);
  }
}
