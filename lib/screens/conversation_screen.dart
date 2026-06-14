import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';

class ConversationScreen extends StatefulWidget {
  final Conversation conversation;
  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  static const Color brand = Color(0xFF5D7048);
  static const Color brandLight = Color(0xFF6F9A84);

  final _chat = ChatService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  List<Message> _messages = [];
  StreamSubscription? _sub;
  bool _sending = false;
  String? _error;

  String get _me => _chat.currentUserId ?? '';
  bool get _iAmParent => _me == widget.conversation.parentId;

  @override
  void initState() {
    super.initState();
    // Reset unread for this conversation as soon as we open it.
    _markRead();
    _sub = _chat.messageStream(widget.conversation.id).listen(
      (rows) {
        if (!mounted) return;
        final hadIncoming = rows.any((m) =>
            m.senderId != _me &&
            !_messages.any((existing) => existing.id == m.id));
        setState(() => _messages = rows);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        // If a new message from the other party just arrived while we're
        // still in the screen, mark it read immediately so the badge stays
        // at zero for this conversation.
        if (hadIncoming) _markRead();
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      },
    );
  }

  Future<void> _markRead() async {
    try {
      await _chat.markConversationRead(
        widget.conversation.id,
        isParent: _iAmParent,
      );
    } catch (_) {
      // Non-fatal — badge will catch up on the next refresh.
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _chat.sendMessage(widget.conversation.id, text);
      _inputController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't send: $e"),
          backgroundColor: const Color(0xFFB23A48),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iAmParent = _me == widget.conversation.parentId;
    final peerName = iAmParent
        ? (widget.conversation.business?.name ?? 'Provider')
        : (widget.conversation.parent?.fullName ?? 'Parent');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: brandLight.withAlpha(30),
              child: Text(
                peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: brand,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                peerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _error != null
                  ? _errorView()
                  : _messages.isEmpty
                      ? _emptyView()
                      : ListView.builder(
                          controller: _scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final mine = m.senderId == _me;
                            final showTime = _shouldShowTime(i);
                            return Column(
                              crossAxisAlignment: mine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (showTime)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    child: Center(
                                      child: Text(
                                        _humanTime(m.createdAt),
                                        style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF999999),
                                        ),
                                      ),
                                    ),
                                  ),
                                _MessageBubble(message: m, mine: mine),
                                const SizedBox(height: 4),
                              ],
                            );
                          },
                        ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  bool _shouldShowTime(int i) {
    if (i == 0) return true;
    final prev = _messages[i - 1].createdAt;
    final cur = _messages[i].createdAt;
    return cur.difference(prev).inMinutes > 15;
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.waving_hand_outlined,
                color: Color(0xFFC5D1C9), size: 48),
            const SizedBox(height: 10),
            Text(
              'Say hello',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Send the first message to start the conversation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E7E3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFFAAAAAA),
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9F8),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: brand,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool mine;

  const _MessageBubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine ? const Color(0xFF5D7048) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(mine ? 14 : 2),
          bottomRight: Radius.circular(mine ? 2 : 14),
        ),
        boxShadow: mine
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Text(
        message.body,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: mine ? Colors.white : const Color(0xFF333333),
        ),
      ),
    );
  }
}

String _humanTime(DateTime t) {
  final now = DateTime.now();
  final sameDay = now.year == t.year && now.month == t.month && now.day == t.day;
  String h12() {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hh:$m $period';
  }

  if (sameDay) return 'Today ${h12()}';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[t.month - 1]} ${t.day}, ${h12()}';
}
