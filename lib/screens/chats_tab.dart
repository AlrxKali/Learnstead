import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';
import '../widgets/chats_badged_icon.dart';
import 'conversation_screen.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  static const Color brand = Color(0xFF5D7048);
  static const Color brandLight = Color(0xFF6F9A84);

  final _chat = ChatService();

  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    // Re-fetch on any change to conversations the user can see — RLS already
    // limits this stream to participating rows.
    _sub = _chat.conversationsStream().listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final convs = await _chat.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = convs;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _open(Conversation c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(conversation: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Chats',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
          if (_conversations.isNotEmpty)
            Text(
              '${_conversations.length}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF999999),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _errorView();
    }
    if (_conversations.isEmpty) {
      return _emptyView();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: StreamBuilder<Map<String, int>>(
        stream: _chat.unreadCountsStream(),
        builder: (context, snap) {
          final unread = snap.data ?? const <String, int>{};
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
            itemCount: _conversations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = _conversations[i];
              return _ConversationTile(
                conversation: c,
                currentUserId: _chat.currentUserId,
                unreadCount: unread[c.id] ?? 0,
                onTap: () => _open(c),
              );
            },
          );
        },
      ),
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFB23A48), size: 48),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                color: Color(0xFFC5D1C9), size: 56),
            const SizedBox(height: 10),
            Text(
              'No chats yet',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Open any provider and tap Message to start a conversation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF999999),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Conversation tile
// ============================================================

class _ConversationTile extends StatelessWidget {
  static const Color brand = Color(0xFF5D7048);
  static const Color brandLight = Color(0xFF6F9A84);

  final Conversation conversation;
  final String? currentUserId;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iAmParent = currentUserId == conversation.parentId;
    final peerName = iAmParent
        ? (conversation.business?.name ?? 'Provider')
        : (conversation.parent?.fullName ?? 'Parent');
    final initial =
        peerName.isNotEmpty ? peerName[0].toUpperCase() : '?';
    final preview = conversation.lastMessageBody ?? 'No messages yet.';
    final time = conversation.lastMessageAt ?? conversation.createdAt;
    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: brandLight.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: brand,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          peerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                      Text(
                        _relativeTime(time),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: hasUnread
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: hasUnread
                              ? brand
                              : const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: hasUnread
                                ? const Color(0xFF333333)
                                : const Color(0xFF777777),
                            fontWeight: hasUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        UnreadBadge(count: unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "5m" / "2h" / "Jun 3" — quick relative formatter.
String _relativeTime(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[t.month - 1]} ${t.day}';
}
