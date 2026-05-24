import 'api_client.dart';
import 'auth_service.dart';

class BusinessCategory {
  final String id;
  final String name;

  BusinessCategory({required this.id, required this.name});

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class Business {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? phone;
  final String? email;
  final String? website;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? categoryId;
  final BusinessCategory? category;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.phone,
    required this.email,
    required this.website,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.categoryId,
    required this.category,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    return Business(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
      categoryId: json['category_id'] as String?,
      category: cat is Map<String, dynamic>
          ? BusinessCategory.fromJson(cat)
          : null,
    );
  }

  String? get formattedAddress {
    final parts = <String>[];
    if (addressLine1 != null && addressLine1!.isNotEmpty) parts.add(addressLine1!);
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    final cityStateZip = [
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
    ].join(', ');
    final tail = [
      if (cityStateZip.isNotEmpty) cityStateZip,
      if (zipCode != null && zipCode!.isNotEmpty) zipCode!,
    ].join(' ');
    if (tail.isNotEmpty) parts.add(tail);
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}

class BusinessNotFoundException extends ApiException {
  BusinessNotFoundException() : super('Business not found', statusCode: 404);
}

class BusinessService {
  final ApiClient _client = ApiClient();

  String _requireToken() {
    final token = Session.current?.accessToken;
    if (token == null) {
      throw ApiException('You are not signed in.');
    }
    return token;
  }

  Future<List<BusinessCategory>> listCategories() async {
    final response = await _client.getJson(
      '/businesses/categories',
      token: _requireToken(),
    );
    final list = response as List<dynamic>;
    return list
        .map((e) => BusinessCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Business> createBusiness({
    required String name,
    String? description,
    String? phone,
    String? email,
    String? website,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    String? categoryId,
  }) async {
    final body = <String, dynamic>{'name': name};
    void addIfPresent(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        body[key] = value.trim();
      }
    }

    addIfPresent('description', description);
    addIfPresent('phone', phone);
    addIfPresent('email', email);
    addIfPresent('website', website);
    addIfPresent('address_line1', addressLine1);
    addIfPresent('address_line2', addressLine2);
    addIfPresent('city', city);
    addIfPresent('state', state);
    addIfPresent('zip_code', zipCode);
    if (categoryId != null) body['category_id'] = categoryId;

    final response = await _client.postJson(
      '/businesses',
      body,
      token: _requireToken(),
    );
    return Business.fromJson(response as Map<String, dynamic>);
  }

  Future<Business> getMyBusiness() async {
    try {
      final response = await _client.getJson(
        '/businesses/me',
        token: _requireToken(),
      );
      return Business.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw BusinessNotFoundException();
      }
      rethrow;
    }
  }

  Future<Business> updateMyBusiness({
    String? name,
    String? description,
    String? phone,
    String? email,
    String? website,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    String? categoryId,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;
    if (website != null) body['website'] = website;
    if (addressLine1 != null) body['address_line1'] = addressLine1;
    if (addressLine2 != null) body['address_line2'] = addressLine2;
    if (city != null) body['city'] = city;
    if (state != null) body['state'] = state;
    if (zipCode != null) body['zip_code'] = zipCode;
    if (categoryId != null) body['category_id'] = categoryId;

    final response = await _client.putJson(
      '/businesses/me',
      body,
      token: _requireToken(),
    );
    return Business.fromJson(response as Map<String, dynamic>);
  }
}
