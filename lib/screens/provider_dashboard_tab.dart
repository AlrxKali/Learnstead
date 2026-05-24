import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/business_service.dart';

class ProviderDashboardTab extends StatefulWidget {
  final void Function(int tabIndex) onTabSwitch;

  const ProviderDashboardTab({super.key, required this.onTabSwitch});

  @override
  State<ProviderDashboardTab> createState() => _ProviderDashboardTabState();
}

class _ProviderDashboardTabState extends State<ProviderDashboardTab> {
  final _businessService = BusinessService();
  Business? _business;
  bool _isLoadingBusiness = true;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final business = await _businessService.getMyBusiness();
      if (!mounted) return;
      setState(() {
        _business = business;
        _isLoadingBusiness = false;
      });
    } on BusinessNotFoundException {
      if (!mounted) return;
      setState(() => _isLoadingBusiness = false);
    } on ApiException {
      // Non-fatal for the dashboard; greeting just falls back.
      if (!mounted) return;
      setState(() => _isLoadingBusiness = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildGreetingHeader(),
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
    );
  }

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
        Container(
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
      ],
    );
  }

  Widget _buildStatCards() {
    final stats = [
      _StatItem('Profile Views', '248', Icons.visibility_outlined),
      _StatItem('Inquiries', '12', Icons.mail_outline),
      _StatItem('Saved by Parents', '36', Icons.bookmark_outline),
      _StatItem('Avg Rating', '4.9', Icons.star_outline),
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
      _ActionItem('Share Link', Icons.share_outlined, () {}),
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
        _buildInquiryItem(
          name: 'Jessica Thompson',
          message: "Hi! I'm interested in the STEM workshop for my 8-year-old...",
          time: '2h ago',
          isUnread: true,
          initials: 'JT',
        ),
        const SizedBox(height: 10),
        _buildInquiryItem(
          name: 'Michael Chen',
          message: 'Do you offer any weekend sessions? We are available...',
          time: '5h ago',
          isUnread: false,
          initials: 'MC',
        ),
      ],
    );
  }

  Widget _buildInquiryItem({
    required String name,
    required String message,
    required String time,
    required bool isUnread,
    required String initials,
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
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                        color: const Color(0xFF333333),
                      ),
                    ),
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
        _buildScheduleItem(
          month: 'FEB',
          day: '18',
          title: 'Creative Arts Workshop',
          time: '10:00 AM – 12:00 PM',
          spotsLeft: 3,
        ),
        const SizedBox(height: 10),
        _buildScheduleItem(
          month: 'FEB',
          day: '20',
          title: 'STEM Exploration Session',
          time: '2:00 PM – 4:00 PM',
          spotsLeft: 7,
        ),
      ],
    );
  }

  Widget _buildScheduleItem({
    required String month,
    required String day,
    required String title,
    required String time,
    required int spotsLeft,
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
                const SizedBox(height: 3),
                Text(
                  '$spotsLeft spots left',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFCC6B2E),
                  ),
                ),
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
