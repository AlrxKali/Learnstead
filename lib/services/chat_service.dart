import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight reference to a business inside a conversation row.
class ChatBusinessRef {
  final String id;
  final String name;
  final String ownerId;

  ChatBusinessRef({
    required this.id,
    required this.name,
    required this.ownerId,
  });

  factory ChatBusinessRef.fromJson(Map<String, dynamic> json) =>
      ChatBusinessRef(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerId: json['owner_id'] as String,
      );
}

/// Lightweight reference to the parent on the other end (for providers).
class ChatParentRef {
  final String id;
  final String fullName;

  ChatParentRef({required this.id, required this.fullName});
}

class Conversation {
  final String id;
  final String parentId;
  final String businessId;
  final DateTime? lastMessageAt;
  final String? lastMessageBody;
  final DateTime createdAt;
  final ChatBusinessRef? business;
  final ChatParentRef? parent; // resolved separately when current user is provider

  Conversation({
    required this.id,
    required this.parentId,
    required this.businessId,
    required this.lastMessageAt,
    required this.lastMessageBody,
    required this.createdAt,
    required this.business,
    required this.parent,
  });

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ChatParentRef? parent,
  }) {
    final biz = json['businesses'];
    return Conversation(
      id: json['id'] as String,
      parentId: json['parent_id'] as String,
      businessId: json['business_id'] as String,
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String).toLocal(),
      lastMessageBody: json['last_message_body'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      business: biz is Map<String, dynamic>
          ? ChatBusinessRef.fromJson(biz)
          : null,
      parent: parent,
    );
  }

  Conversation copyWith({ChatParentRef? parent}) => Conversation(
        id: id,
        parentId: parentId,
        businessId: businessId,
        lastMessageAt: lastMessageAt,
        lastMessageBody: lastMessageBody,
        createdAt: createdAt,
        business: business,
        parent: parent ?? this.parent,
      );
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class ChatService {
  SupabaseClient get _sb => Supabase.instance.client;

  String get _userId {
    final id = _sb.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No Supabase session — sign in first.');
    }
    return id;
  }

  /// All conversations the current user can see (parent or provider, RLS
  /// handles the rest). For providers, parent names get resolved with one
  /// follow-up query against profiles.
  Future<List<Conversation>> listConversations() async {
    final rows = await _sb
        .from('conversations')
        .select('*, businesses(id, name, owner_id)')
        .order('last_message_at', ascending: false, nullsFirst: false);

    final conversations = (rows as List)
        .map((r) => Conversation.fromJson(r as Map<String, dynamic>))
        .toList();

    final me = _userId;
    final parentIdsToResolve = conversations
        .where((c) => c.parentId != me)
        .map((c) => c.parentId)
        .toSet()
        .toList();

    if (parentIdsToResolve.isEmpty) return conversations;

    final profileRows = await _sb
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', parentIdsToResolve);
    final byId = <String, ChatParentRef>{};
    for (final row in profileRows as List) {
      final r = row as Map<String, dynamic>;
      byId[r['id'] as String] = ChatParentRef(
        id: r['id'] as String,
        fullName: (r['full_name'] as String?) ?? 'Parent',
      );
    }
    return conversations
        .map((c) => byId.containsKey(c.parentId)
            ? c.copyWith(parent: byId[c.parentId])
            : c)
        .toList();
  }

  /// Open or create the unique conversation between the current user
  /// (parent) and [businessId]. Returns the conversation with business
  /// joined.
  Future<Conversation> getOrCreateForBusiness(String businessId) async {
    final me = _userId;
    final existing = await _sb
        .from('conversations')
        .select('*, businesses(id, name, owner_id)')
        .eq('parent_id', me)
        .eq('business_id', businessId)
        .maybeSingle();
    if (existing != null) {
      return Conversation.fromJson(existing);
    }
    final created = await _sb
        .from('conversations')
        .insert({'parent_id': me, 'business_id': businessId})
        .select('*, businesses(id, name, owner_id)')
        .single();
    return Conversation.fromJson(created);
  }

  Future<List<Message>> listMessages(String conversationId) async {
    final rows = await _sb
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (rows as List)
        .map((r) => Message.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Realtime stream of messages for [conversationId]. Emits a fresh list
  /// on every change (insert / update / delete) — RLS filters out anything
  /// the user isn't a participant of.
  Stream<List<Message>> messageStream(String conversationId) {
    return _sb
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) =>
            rows.map((r) => Message.fromJson(r)).toList(growable: false));
  }

  /// Realtime stream of conversations. Re-fires whenever anything changes
  /// (incl. last_message_at via the trigger), so the list can re-render.
  Stream<List<Map<String, dynamic>>> conversationsStream() {
    return _sb.from('conversations').stream(primaryKey: ['id']);
  }

  Future<void> sendMessage(String conversationId, String body) async {
    final me = _userId;
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _sb.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': me,
      'body': trimmed,
    });
  }

  /// Set the appropriate last_read_at on a conversation to now(). Picks
  /// the parent column if [isParent] is true, otherwise the provider one.
  Future<void> markConversationRead(
    String conversationId, {
    required bool isParent,
  }) async {
    final col = isParent ? 'parent_last_read_at' : 'provider_last_read_at';
    await _sb
        .from('conversations')
        .update({col: DateTime.now().toUtc().toIso8601String()})
        .eq('id', conversationId);
  }

  /// Stream of per-conversation unread counts for the current user.
  ///
  /// Emits an initial map immediately, then re-emits whenever a new
  /// message is inserted into any of your conversations OR any of your
  /// conversation rows change (e.g. last_read_at update). The map keys
  /// are conversation IDs; only conversations with > 0 unread are
  /// present, so the sum of values is the total badge number.
  Stream<Map<String, int>> unreadCountsStream() async* {
    final controller = StreamController<Map<String, int>>();
    Map<String, int> last = const {};

    Future<void> push() async {
      try {
        final rows = await _sb.rpc('get_unread_counts');
        final next = <String, int>{};
        for (final row in rows as List) {
          final r = row as Map<String, dynamic>;
          next[r['conversation_id'] as String] = (r['unread_count'] as num).toInt();
        }
        if (!_mapEquals(next, last)) {
          last = next;
          if (!controller.isClosed) controller.add(next);
        }
      } catch (_) {
        // Ignore intermittent errors — UI will catch up on next event.
      }
    }

    await push(); // initial value

    final msgSub = _sb.from('messages').stream(primaryKey: ['id']).listen((_) {
      push();
    });
    final convSub =
        _sb.from('conversations').stream(primaryKey: ['id']).listen((_) {
      push();
    });

    controller.onCancel = () async {
      await msgSub.cancel();
      await convSub.cancel();
    };

    yield* controller.stream;
  }

  String? get currentUserId => _sb.auth.currentUser?.id;
}

bool _mapEquals(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
