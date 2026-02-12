import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const Color activeColor = Color(0xFF5D7048);
  static const Color inactiveColor = Color(0xFFC5D1C9);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showBusinessDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header image with close button and heart
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.asset(
                        'static/landscapes/lake.png',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(220),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(220),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 20,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                // Business name and rating
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'static/activity cards/Therapies.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Three Points Therapy',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (_) => const Icon(
                                    Icons.star,
                                    color: Color(0xFFFFCC00),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '4.9 (12 Reviews)',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: const Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Tagline
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'Helping children find their voice since 2012',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: activeColor,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // About
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Three Points Therapy is a pediatric speech-language '
                        'pathology practice dedicated to helping children '
                        'overcome communication challenges. Our team of '
                        'licensed SLPs specializes in articulation, language '
                        'delays, stuttering, and social communication skills.',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: const Color(0xFF555555),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // Services
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildServiceChip('Speech Articulation'),
                      _buildServiceChip('Language Development'),
                      _buildServiceChip('Fluency / Stuttering'),
                      _buildServiceChip('Social Communication'),
                      _buildServiceChip('Early Intervention'),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // Details grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(Icons.check_circle, 'Ages 0 - 18'),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.location_on_outlined, '4.2 miles away'),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.laptop_mac, 'In-person & Online'),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.access_time, 'Mon - Fri, 8:00 AM - 5:00 PM'),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.phone_outlined, '(555) 234-5678'),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.language, 'www.threepointstherapy.com'),
                    ],
                  ),
                ),
                // Request Info button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: const Color(0xFFCC6B2E),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Request Info',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: activeColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: const Color(0xFF555555),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(String imagePath, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
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
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset(
                    'static/home.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    bottom: 16,
                    left: 50,
                    right: 50,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter zip code...',
                                hintStyle: GoogleFonts.nunito(
                                  color: const Color(0xFFAAAAAA),
                                  fontSize: 13,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 0,
                                ),
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCC6B2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  child: Text(
                                    'Search',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildActivityCard(
                      'static/activity cards/Art and Music.png',
                      'Art & Music',
                    ),
                    const SizedBox(width: 12),
                    _buildActivityCard(
                      'static/activity cards/Therapies.png',
                      'Therapies',
                    ),
                    const SizedBox(width: 12),
                    _buildActivityCard(
                      'static/activity cards/Co-ops.png',
                      'Co-ops',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => _showBusinessDetail(context),
                  child: Container(
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
                    children: [
                      // Header row: thumbnail, name + stars, heart
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'static/activity cards/Therapies.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Three Points Therapy',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (_) => const Icon(
                                          Icons.star,
                                          color: Color(0xFFFFCC00),
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(12 Reviews)',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          color: const Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      const Divider(height: 1, thickness: 1, indent: 10, endIndent: 10),
                      // Check marks row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: activeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ages 0 - 18',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: const Color(0xFF555555),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.check_circle,
                              color: activeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'In-person & Online',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: const Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Landscape image with Request Info button
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Image.asset(
                              'static/landscapes/landscape.png',
                              width: double.infinity,
                              height: 70,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCC6B2E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 9,
                                      ),
                                      child: Text(
                                        'Request Info',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Planner',
          ),
        ],
      ),
    );
  }
}
