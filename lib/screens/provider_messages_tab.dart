import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProviderMessagesTab extends StatefulWidget {
  const ProviderMessagesTab({super.key});

  @override
  State<ProviderMessagesTab> createState() => _ProviderMessagesTabState();
}

class _ProviderMessagesTabState extends State<ProviderMessagesTab> {
  int? _selectedConversation;
  String _activeFilter = 'All';

  final _conversations = const [
    _Conversation(
      name: 'Jessica Thompson',
      initials: 'JT',
      preview: "Hi! I'm interested in the STEM workshop for my 8-year-old. Is there still availability?",
      time: '2h ago',
      isUnread: true,
      isStarred: false,
      label: 'Enrollment',
    ),
    _Conversation(
      name: 'Michael Chen',
      initials: 'MC',
      preview: 'Do you offer any weekend sessions? We are available mostly on Saturdays.',
      time: '5h ago',
      isUnread: true,
      isStarred: true,
      label: 'General',
    ),
    _Conversation(
      name: 'Emily Rodriguez',
      initials: 'ER',
      preview: 'Thank you so much! We will see you on Monday then.',
      time: 'Yesterday',
      isUnread: false,
      isStarred: false,
      label: 'Enrollment',
    ),
    _Conversation(
      name: 'David Park',
      initials: 'DP',
      preview: 'Can you share more details about the nature exploration program?',
      time: 'Yesterday',
      isUnread: true,
      isStarred: false,
      label: 'Inquiry',
    ),
    _Conversation(
      name: 'Lisa Martinez',
      initials: 'LM',
      preview: 'My kids had such a great time last week! When is the next session?',
      time: '2 days ago',
      isUnread: false,
      isStarred: true,
      label: 'Follow-up',
    ),
  ];

  final _mockMessages = const [
    _Message(
      text: "Hi! I'm interested in the STEM workshop for my 8-year-old. Is there still availability for the Tuesday afternoon session?",
      isMe: false,
      time: '10:23 AM',
    ),
    _Message(
      text: "Hi Jessica! Yes, we still have 3 spots open for the Tuesday STEM workshop. It runs from 2:00-4:00 PM and is designed for ages 7-10.",
      isMe: true,
      time: '10:45 AM',
    ),
    _Message(
      text: "That sounds perfect! What materials does my child need to bring?",
      isMe: false,
      time: '11:02 AM',
    ),
    _Message(
      text: "We provide all materials! Just make sure they wear clothes that can get a little messy. We do lots of hands-on experiments. 😊",
      isMe: true,
      time: '11:15 AM',
    ),
    _Message(
      text: "Wonderful! How do I sign up?",
      isMe: false,
      time: '11:20 AM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_selectedConversation != null) {
      return _buildConversationDetail(_conversations[_selectedConversation!]);
    }
    return _buildInboxList();
  }

  Widget _buildInboxList() {
    final filters = ['All', 'Unread', 'Starred'];
    final unreadCount =
        _conversations.where((c) => c.isUnread).length;

    final filtered = _conversations.where((c) {
      if (_activeFilter == 'Unread') return c.isUnread;
      if (_activeFilter == 'Starred') return c.isStarred;
      return true;
    }).toList();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F9A84),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount new',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E7E3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Color(0xFFC5D1C9)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: const Color(0xFF333333)),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: GoogleFonts.nunito(
                          fontSize: 14, color: const Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: filters.map((filter) {
              final isActive = _activeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _activeFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF5D7048)
                          : const Color(0xFFF7F9F8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF5D7048)
                            : const Color(0xFFE0E7E3),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            isActive ? Colors.white : const Color(0xFF555555),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Conversation list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final convo = filtered[index];
              final originalIndex = _conversations.indexOf(convo);
              return _buildConversationTile(convo, originalIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(_Conversation convo, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedConversation = index),
      child: Container(
        padding: const EdgeInsets.all(14),
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
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6F9A84).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  convo.initials,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D7048),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                convo.name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: convo.isUnread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                convo.label,
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF999999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        convo.time,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF999999),
                          ),
                        ),
                      ),
                      if (convo.isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6F9A84),
                            shape: BoxShape.circle,
                          ),
                        ),
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

  Widget _buildConversationDetail(_Conversation convo) {
    final messageController = TextEditingController();

    return Column(
      children: [
        // Header with back arrow
        Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedConversation = null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E7E3)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6F9A84).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    convo.initials,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5D7048),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      convo.name,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      convo.label,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: _mockMessages.length,
            itemBuilder: (context, index) {
              final msg = _mockMessages[index];
              return _buildMessageBubble(msg);
            },
          ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE0E7E3)),
                    ),
                    child: TextField(
                      controller: messageController,
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: const Color(0xFF333333)),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.nunito(
                            fontSize: 14, color: const Color(0xFFAAAAAA)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D7048),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe
              ? const Color(0xFF5D7048).withAlpha(20)
              : const Color(0xFFF7F9F8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Conversation {
  final String name;
  final String initials;
  final String preview;
  final String time;
  final bool isUnread;
  final bool isStarred;
  final String label;

  const _Conversation({
    required this.name,
    required this.initials,
    required this.preview,
    required this.time,
    required this.isUnread,
    required this.isStarred,
    required this.label,
  });
}

class _Message {
  final String text;
  final bool isMe;
  final String time;

  const _Message({
    required this.text,
    required this.isMe,
    required this.time,
  });
}
