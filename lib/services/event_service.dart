import 'api_client.dart';
import 'auth_service.dart';

enum EventType { session, consultation }

enum EventStatus { confirmed, pending, cancelled }

extension EventTypeWire on EventType {
  String get wire => name;
  String get label => this == EventType.session ? 'Session' : 'Consultation';

  static EventType fromWire(String? v) =>
      v == 'consultation' ? EventType.consultation : EventType.session;
}

extension EventStatusWire on EventStatus {
  String get wire => name;

  String get label {
    switch (this) {
      case EventStatus.confirmed:
        return 'Confirmed';
      case EventStatus.pending:
        return 'Pending';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  static EventStatus fromWire(String? v) {
    switch (v) {
      case 'pending':
        return EventStatus.pending;
      case 'cancelled':
        return EventStatus.cancelled;
      default:
        return EventStatus.confirmed;
    }
  }
}

/// An entry on a provider's schedule.
class BusinessEvent {
  final String id;
  final String businessId;
  final String title;
  final String? description;
  final EventType type;
  final DateTime startsAt; // local time
  final DateTime endsAt; // local time
  final int? capacity;
  final EventStatus status;

  BusinessEvent({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.type,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.status,
  });

  factory BusinessEvent.fromJson(Map<String, dynamic> json) => BusinessEvent(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        type: EventTypeWire.fromWire(json['event_type'] as String?),
        startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
        capacity: (json['capacity'] as num?)?.toInt(),
        status: EventStatusWire.fromWire(json['status'] as String?),
      );
}

class EventService {
  final ApiClient _client = ApiClient();

  String _requireToken() {
    final t = Session.accessToken;
    if (t == null) throw ApiException('You are not signed in.');
    return t;
  }

  /// The signed-in provider's events with starts_at in [from, to].
  Future<List<BusinessEvent>> listMyEvents({DateTime? from, DateTime? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();
    final qs = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    final r = await _client.getJson(
      '/businesses/me/events$qs',
      token: _requireToken(),
    );
    return _parseList(r);
  }

  /// Upcoming, non-cancelled events of any business (for parents).
  Future<List<BusinessEvent>> listUpcomingForBusiness(
    String businessId, {
    int limit = 5,
  }) async {
    final r = await _client.getJson(
      '/businesses/$businessId/events?limit=$limit',
      token: _requireToken(),
    );
    return _parseList(r);
  }

  Future<BusinessEvent> createEvent({
    required String title,
    String? description,
    required EventType type,
    required DateTime startsAt,
    required DateTime endsAt,
    int? capacity,
    EventStatus status = EventStatus.confirmed,
  }) async {
    final r = await _client.postJson(
      '/businesses/me/events',
      {
        'title': title,
        'description': description,
        'event_type': type.wire,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'capacity': capacity,
        'status': status.wire,
      },
      token: _requireToken(),
    );
    return BusinessEvent.fromJson(r as Map<String, dynamic>);
  }

  /// Full replace of the editable fields (null clears description/capacity).
  Future<BusinessEvent> updateEvent(
    String eventId, {
    required String title,
    String? description,
    required EventType type,
    required DateTime startsAt,
    required DateTime endsAt,
    int? capacity,
    required EventStatus status,
  }) async {
    final r = await _client.patchJson(
      '/businesses/me/events/$eventId',
      {
        'title': title,
        'description': description,
        'event_type': type.wire,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'capacity': capacity,
        'status': status.wire,
      },
      token: _requireToken(),
    );
    return BusinessEvent.fromJson(r as Map<String, dynamic>);
  }

  Future<void> deleteEvent(String eventId) async {
    await _client.deleteJson(
      '/businesses/me/events/$eventId',
      token: _requireToken(),
    );
  }

  List<BusinessEvent> _parseList(dynamic r) => (r as List<dynamic>)
      .map((e) => BusinessEvent.fromJson(e as Map<String, dynamic>))
      .toList();
}
