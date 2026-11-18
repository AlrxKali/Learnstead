import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/business_service.dart';
import '../services/chat_service.dart';
import '../services/event_service.dart';
import '../utils/datetime_format.dart';
import 'account_screen.dart';
import 'conversation_screen.dart';

class ProviderDashboardTab extends StatefulWidget {
  final void Function(int tabIndex) onTabSwitch;

  /// Fires when the dashboard should re-fetch (e.g. the tab is re-selected
  /// after the provider edited their schedule elsewhere).
  final Listenable? refresh;

  const ProviderDashboardTab({
    super.key,
    required this.onTabSwitch,
    this.refresh,
  });

  @override
  State<ProviderDashboardTab> createState() => _ProviderDashboardTabState();
}

class _ProviderDashboardTabState extends State<ProviderDashboardTab> {
  final _businessService = BusinessService();
  final _eventService = EventService();
  final _chatService = ChatService();

  Business? _business;
  bool _isLoadingBusiness = true;
  BusinessStats? _stats;
  List<Conversation>? _inquiries;
  Map<String, int> _unread = const {};
  List<BusinessEvent>? _upcoming;

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_loadAll);
    _loadAll();
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_loadAll);
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadBusiness(),
      _loadStats(),
      _loadInquiries(),
      _loadUpcoming(),
    ]);
  }

  Future<void> _loadBusiness() async {
    try {
      final business = await _businessService.getMyBusiness();
      if (!mounted) return;
      setState(() {
        _business = business;
        _isLoadingBusiness = false;
      });
    } on ApiException {
      // Not found or unreachable: the greeting falls back and the setup
      // prompt shows.
      if (!mounted) return;
      setState(() => _isLoadingBusiness = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _businessService.getMyStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } on ApiException {
      if (!mounted) return;
      setState(() => _stats ??= const BusinessStats());
    }
  }

  Future<void> _loadInquiries() async {
    try {
      final conversations = await _chatService.listConversations();
      final unread = await _chatService.unreadCounts();
      if (!mounted) return;
      setState(() {
        _inquiries = conversations;
        _unread = unread;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _inquiries ??= const []);
    }
  }

  Future<void> _loadUpcoming() async {
    try {
      final events = await _eventService.listMyEvents(from: DateTime.now());
      if (!mounted) return;
      setState(() {
        _upcoming = events
            .where((e) => e.status != EventStatus.cancelled)
            .take(3)
            .toList();
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _upcoming ??= const []);
    }
  }

  Future<void> _shareListing() async {
    final b = _business;
    if (b == null) {
      widget.onTabSwitch(1);
      return;
    }
    final where = b.deliveryMode == DeliveryMode.online
        ? 'Online'
        : [b.city, b.state].where((p) => p != null && p.isNotEmpty).join(', ');
    final lines = [
      'Find ${b.name} on Learnstead',
      [b.category?.name, where]
          .where((p) => p != null && p.isNotEmpty)
          .join(' · '),
      if ((b.website ?? '').isNotEmpty) b.website!,
    ].where((l) => l.isNotEmpty).join('\n');
    await Clipboard.setData(ClipboardData(text: lines));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing details copied to clipboard.')),
    );
  }

  Future<void> _openAccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
  }

  Future<void> _openConversation(Conversation c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConversationScreen(conversation: c)),
    );
    if (mounted) _loadInquiries();
  }

  @override
  Widget build(BuildContext context) {
    final needsSetup = !_isLoadingBusiness && _business == null;
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildGreetingHeader(),
            if (needsSetup) ...[
              const SizedBox(height: 16),
              _buildSetupPrompt(),
            ],
            const SizedBox(height: 24),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 28),
            _buildRecentInquiries(),
            const SizedBox(height: 28),
            _buildUpcomingSchedule(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupPrompt() {
    return GestureDetector(
      onTap: () => widget.onTabSwitch(1),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5E5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCC8A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined,
                color: Color(0xFFCC6B2E), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Finish setting up your business so families can find you.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7A4A1E),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCC6B2E)),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E7E3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFAAAAAA),
        ),
      ),
    );
  }

  Widget _sectionLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _buildGreetingHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final displayName = _business?.name ??
        (_isLoadingBusiness ? '…' : 'Your business');
    final initial = (_business?.name.isNotEmpty ?? false)
        ? _business!.name[0].toUpperCase()
        : '?';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Account',
          child: GestureDetector(
            onTap: _openAccount,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6F9A84).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5D7048),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    final st = _stats;
    String n(int? v) => st == null ? '…' : '${v ?? 0}';
    final rating = st == null
        ? '…'
        : (st.avgRating == null ? '—' : st.avgRating!.toStringAsFixed(1));
    final ratingLabel = (st?.reviewCount ?? 0) > 0
        ? 'Avg Rating (${st!.reviewCount})'
        : 'Avg Rating';
    final stats = [
      _StatItem('Profile Views', n(st?.profileViews), Icons.visibility_outlined),
      _StatItem('Inquiries', n(st?.inquiries), Icons.mail_outline),
      _StatItem('Saved by Parents', n(st?.savedCount), Icons.bookmark_outline),
      _StatItem(ratingLabel, rating, Icons.star_outline),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: stats.map((stat) {
        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat.icon, size: 20, color: const Color(0xFF6F9A84)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    stat.label,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _ActionItem('Edit Profile', Icons.edit_outlined, () => widget.onTabSwitch(1)),
      _ActionItem('New Event', Icons.event_outlined, () => widget.onTabSwitch(3)),
      _ActionItem('Share Listing', Icons.share_outlined, _shareListing),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: action == actions.last ? 0 : 10,
                ),
                child: GestureDetector(
                  onTap: action.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E7E3)),
                    ),
                    child: Column(
                      children: [
                        Icon(action.icon, size: 22, color: const Color(0xFF5D7048)),
                        const SizedBox(height: 6),
                        Text(
                          action.label,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentInquiries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Inquiries',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onTabSwitch(2),
              child: Text(
                'View all',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6F9A84),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_inquiries == null)
          _sectionLoading()
        else if (_inquiries!.isEmpty)
          _emptyCard('No inquiries yet. Messages from parents show up here.')
        else
          ..._inquiries!.take(3).map((c) {
            final name = c.parent?.fullName ?? 'Parent';
            final when = c.lastMessageAt ?? c.createdAt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildInquiryItem(
                name: name,
                message: c.lastMessageBody ?? 'No messages yet.',
                time: formatTimeAgo(when),
                isUnread: (_unread[c.id] ?? 0) > 0,
                initials: _initials(name),
                onTap: () => _openConversation(c),
              ),
            );
          }),
      ],
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildInquiryItem({
    required String name,
    required String message,
    required String time,
    required bool isUnread,
    required String initials,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _inquiryCard(name, message, time, isUnread, initials),
    );
  }

  Widget _inquiryCard(
    String name,
    String message,
    String time,
    bool isUnread,
    String initials,
  ) {
    return Container(
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6F9A84).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
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
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight:
                              isUnread ? FontWeight.w800 : FontWeight.w700,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
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
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ),
                    if (isUnread) ...[
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
    );
  }

  Widget _buildUpcomingSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Schedule',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF333333),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onTabSwitch(3),
              child: Text(
                'View all',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6F9A84),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_upcoming == null)
          _sectionLoading()
        else if (_upcoming!.isEmpty)
          _emptyCard('Nothing coming up. Add an event from the Schedule tab.')
        else
          ..._upcoming!.map((e) {
            final sameDay = isSameDay(e.startsAt, DateTime.now());
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildScheduleItem(
                month: monthAbbr(e.startsAt),
                day: '${e.startsAt.day}',
                title: e.title,
                time: formatTimeRange(e.startsAt, e.endsAt),
                footnote: [
                  if (sameDay) 'Today',
                  if (e.status == EventStatus.pending) 'Pending',
                  if (e.capacity != null)
                    '${e.capacity} spot${e.capacity == 1 ? '' : 's'}',
                ].join(' · '),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildScheduleItem({
    required String month,
    required String day,
    required String title,
    required String time,
    required String footnote,
  }) {
    return Container(
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
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5D7048),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                Text(
                  day,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF999999),
                  ),
                ),
                if (footnote.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    footnote,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFCC6B2E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(this.label, this.value, this.icon);
}

class _ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionItem(this.label, this.icon, this.onTap);
}
