import 'api_client.dart';
import 'auth_service.dart';

enum SessionStatus { planned, cancelled }

extension SessionStatusWire on SessionStatus {
  String get wire =>
      this == SessionStatus.planned ? 'planned' : 'cancelled';

  static SessionStatus fromWire(String? v) =>
      v == 'cancelled' ? SessionStatus.cancelled : SessionStatus.planned;
}

class PlanBusinessRef {
  final String id;
  final String name;
  PlanBusinessRef({required this.id, required this.name});

  factory PlanBusinessRef.fromJson(Map<String, dynamic> json) =>
      PlanBusinessRef(id: json['id'] as String, name: json['name'] as String);
}

class Plan {
  final String id;
  final String parentId;
  final String? businessId;
  final PlanBusinessRef? business;
  final String title;
  final String? notes;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.parentId,
    required this.businessId,
    required this.business,
    required this.title,
    required this.notes,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    final biz = json['business'];
    return Plan(
      id: json['id'] as String,
      parentId: json['parent_id'] as String,
      businessId: json['business_id'] as String?,
      business: biz is Map<String, dynamic>
          ? PlanBusinessRef.fromJson(biz)
          : null,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class PlanSession {
  final String id;
  final String planId;
  final DateTime startsAt;
  final DateTime endsAt;
  final SessionStatus status;
  final String? notes;
  final DateTime createdAt;

  PlanSession({
    required this.id,
    required this.planId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  factory PlanSession.fromJson(Map<String, dynamic> json) {
    return PlanSession(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      status: SessionStatusWire.fromWire(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Duration get duration => endsAt.difference(startsAt);
}

class PlannerService {
  final ApiClient _client = ApiClient();

  String _requireToken() {
    final t = Session.current?.accessToken;
    if (t == null) throw ApiException('You are not signed in.');
    return t;
  }

  // ---- plans ----

  Future<List<Plan>> listPlans() async {
    final r = await _client.getJson('/plans', token: _requireToken());
    return (r as List<dynamic>)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Plan> createPlan({
    required String title,
    String? notes,
    String? businessId,
    String? color,
  }) async {
    final body = <String, dynamic>{'title': title};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (businessId != null) body['business_id'] = businessId;
    if (color != null) body['color'] = color;
    final r = await _client.postJson('/plans', body, token: _requireToken());
    return Plan.fromJson(r as Map<String, dynamic>);
  }

  Future<Plan> updatePlan(
    String planId, {
    String? title,
    String? notes,
    String? businessId,
    String? color,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (notes != null) body['notes'] = notes;
    if (businessId != null) body['business_id'] = businessId;
    if (color != null) body['color'] = color;
    final r = await _client.patchJson(
      '/plans/$planId',
      body,
      token: _requireToken(),
    );
    return Plan.fromJson(r as Map<String, dynamic>);
  }

  Future<void> deletePlan(String planId) async {
    await _client.deleteJson('/plans/$planId', token: _requireToken());
  }

  // ---- sessions ----

  Future<List<PlanSession>> listSessions({
    DateTime? from,
    DateTime? to,
    String? planId,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();
    if (planId != null) params['plan_id'] = planId;
    final qs = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final r = await _client.getJson('/sessions$qs', token: _requireToken());
    return (r as List<dynamic>)
        .map((e) => PlanSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlanSession> createSession({
    required String planId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    final r = await _client.postJson(
      '/plans/$planId/sessions',
      body,
      token: _requireToken(),
    );
    return PlanSession.fromJson(r as Map<String, dynamic>);
  }

  Future<PlanSession> updateSession(
    String sessionId, {
    DateTime? startsAt,
    DateTime? endsAt,
    String? notes,
    SessionStatus? status,
  }) async {
    final body = <String, dynamic>{};
    if (startsAt != null) body['starts_at'] = startsAt.toUtc().toIso8601String();
    if (endsAt != null) body['ends_at'] = endsAt.toUtc().toIso8601String();
    if (notes != null) body['notes'] = notes;
    if (status != null) body['status'] = status.wire;
    final r = await _client.patchJson(
      '/sessions/$sessionId',
      body,
      token: _requireToken(),
    );
    return PlanSession.fromJson(r as Map<String, dynamic>);
  }

  Future<PlanSession> cancelSession(String sessionId) =>
      updateSession(sessionId, status: SessionStatus.cancelled);

  Future<PlanSession> reactivateSession(String sessionId) =>
      updateSession(sessionId, status: SessionStatus.planned);

  Future<void> deleteSession(String sessionId) async {
    await _client.deleteJson('/sessions/$sessionId', token: _requireToken());
  }
}
