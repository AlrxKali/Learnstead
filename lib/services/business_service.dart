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
  final String? categoryId;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.categoryId,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
    );
  }
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
}
