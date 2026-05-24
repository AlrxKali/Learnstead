import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/business_service.dart';
import 'provider_home_screen.dart';

class CreateBusinessScreen extends StatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _businessService = BusinessService();

  List<BusinessCategory> _categories = [];
  String? _selectedCategoryId;
  bool _categoriesLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _businessService.listCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _categoriesLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _categoriesLoading = false);
      _showError('Could not load categories: ${e.message}');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Business name is required.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _businessService.createBusiness(
        name: name,
        description: _descriptionController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
        addressLine1: _address1Controller.text,
        addressLine2: _address2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipController.text,
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProviderHomeScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFB23A48)),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFFAAAAAA)),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFFC5D1C9), size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F9F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6F9A84)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F9A84).withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 32,
                    color: Color(0xFF5D7048),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Set up your business',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell families about your learning services',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),

              // --- Basic Info ---
              _buildSectionHeader('Basic Info', Icons.info_outline),

              _buildLabel('Business Name *'),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                decoration: _inputDecoration(
                  hint: 'e.g. Bright Minds Tutoring',
                  prefixIcon: Icons.business_outlined,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Category'),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                onChanged: _categoriesLoading
                    ? null
                    : (value) => setState(() => _selectedCategoryId = value),
                style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFC5D1C9)),
                decoration: InputDecoration(
                  hintText: _categoriesLoading
                      ? 'Loading categories…'
                      : 'Select a category',
                  hintStyle: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFFAAAAAA)),
                  prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFFC5D1C9), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF7F9F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
                  ),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: GoogleFonts.nunito(fontSize: 15)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              _buildLabel('Description'),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                decoration: InputDecoration(
                  hintText: 'Briefly describe what you offer...',
                  hintStyle: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFFAAAAAA)),
                  filled: true,
                  fillColor: const Color(0xFFF7F9F8),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
                  ),
                ),
              ),

              // --- Contact ---
              _buildSectionHeader('Contact', Icons.phone_outlined),

              _buildLabel('Phone'),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                decoration: _inputDecoration(
                  hint: '(555) 123-4567',
                  prefixIcon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Email'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                decoration: _inputDecoration(
                  hint: 'contact@yourbusiness.com',
                  prefixIcon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Website'),
              TextField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                decoration: _inputDecoration(
                  hint: 'https://yourbusiness.com',
                  prefixIcon: Icons.language_outlined,
                ),
              ),

              // --- Address ---
              _buildSectionHeader('Address', Icons.location_on_outlined),

              _buildLabel('Address Line 1'),
              TextField(
                controller: _address1Controller,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                decoration: _inputDecoration(
                  hint: '123 Main Street',
                  prefixIcon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Address Line 2'),
              TextField(
                controller: _address2Controller,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                decoration: _inputDecoration(
                  hint: 'Suite, Apt, Unit (optional)',
                  prefixIcon: Icons.apartment_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // City, State, Zip in a row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('City'),
                        TextField(
                          controller: _cityController,
                          textCapitalization: TextCapitalization.words,
                          style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                          decoration: InputDecoration(
                            hintText: 'City',
                            hintStyle: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFFAAAAAA)),
                            filled: true,
                            fillColor: const Color(0xFFF7F9F8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('State'),
                        TextField(
                          controller: _stateController,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                          decoration: InputDecoration(
                            hintText: 'State',
                            hintStyle: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFFAAAAAA)),
                            filled: true,
                            fillColor: const Color(0xFFF7F9F8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Zip'),
                        TextField(
                          controller: _zipController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF333333)),
                          decoration: InputDecoration(
                            hintText: 'Zip',
                            hintStyle: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFFAAAAAA)),
                            filled: true,
                            fillColor: const Color(0xFFF7F9F8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE0E7E3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF6F9A84), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Create button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D7048),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Business',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
