import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/widgets/deleted_items_button.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../providers/chat_provider.dart';
import 'chat_room_page.dart';

/// One route for every role: a company goes straight into its own
/// conversation; superAdmin sees the list of every company's conversation.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Session.isSuperAdmin) return const _ChatList();
    return ChatRoomPage(
      companyId: Session.companyId ?? '',
      companyName: Session.companyName ?? '',
      isRoot: true,
    );
  }
}

class _ChatList extends ConsumerStatefulWidget {
  const _ChatList();

  @override
  ConsumerState<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<_ChatList> {
  final _searchCtrl = TextEditingController();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // No socket yet — refresh the list every 10s (old rows stay while it reloads).
    _poll = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) ref.invalidate(chatConversationsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chatsAsync = ref.watch(chatConversationsProvider);
    final fmt = DateFormat('dd MMM, h:mm a');

    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Chatbot', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          DeletedItemsButton(
            title: 'Deleted chats',
            listPath: ApiEndpoints.chatConversations,
            restorePath: (c) => '${ApiEndpoints.chatConversations}/${c['company_id']}/restore',
            labelOf: (c) => (c['company_name'] ?? '').toString(),
            onRestored: () => ref.invalidate(chatConversationsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hintText: 'Search companies...',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: chatsAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(error: e, onRetry: () => ref.invalidate(chatConversationsProvider)),
              data: (list) {
                final query = _searchCtrl.text.trim().toLowerCase();
                final sorted = list.where((c) => query.isEmpty || c.companyName.toLowerCase().contains(query)).toList()
                  ..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
                if (sorted.isEmpty) {
                  return Center(
                    child: Text(
                      list.isEmpty ? 'No conversations yet' : 'No results',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final c = sorted[i];
                    return RichCardShell.tinted(
                      index: i,
                      onTap: () => context.push(
                        AppRouter.chatRoom,
                        extra: {'companyId': c.companyId, 'companyName': c.companyName},
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                        child: Row(
                          children: [
                            InitialsAvatar(seed: c.companyName, size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c.companyName,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (c.updatedAt != null)
                                        Text(fmt.format(c.updatedAt!), style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.last?.preview ?? 'No messages yet',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
