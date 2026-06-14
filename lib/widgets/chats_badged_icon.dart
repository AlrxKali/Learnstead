import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';

/// Bottom-nav icon that overlays a red unread-count bubble.
///
/// Pass [selected] so the same widget can swap between the outlined and
/// filled chat icons to match `BottomNavigationBarItem.icon` /
/// `activeIcon` semantics.
class ChatsBadgedIcon extends StatelessWidget {
  final bool selected;
  const ChatsBadgedIcon({super.key, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final chat = ChatService();
    return StreamBuilder<Map<String, int>>(
      stream: chat.unreadCountsStream(),
      builder: (context, snap) {
        final total = (snap.data?.values ?? const <int>[])
            .fold<int>(0, (a, b) => a + b);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(selected ? Icons.chat_bubble : Icons.chat_bubble_outline),
            if (total > 0)
              Positioned(
                top: -4,
                right: -8,
                child: _Badge(count: total),
              ),
          ],
        );
      },
    );
  }
}

/// Small red pill used both on the nav icon and on conversation rows.
class UnreadBadge extends StatelessWidget {
  final int count;
  const UnreadBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return _Badge(count: count);
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFB23A48),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
