import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_model.dart';

class MatchService {
  final _client = Supabase.instance.client;

  Future<List<MatchModel>> getMatches() async {
    final uid = _client.auth.currentUser!.id;
    final response = await _client
        .from('matches')
        .select(
          '*, '
          'user1:users!matches_user1_id_fkey(id,username,display_name,avatar_url), '
          'user2:users!matches_user2_id_fkey(id,username,display_name,avatar_url)',
        )
        .or('user1_id.eq.$uid,user2_id.eq.$uid')
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (response as List).map((m) {
      final isUser1 = m['user1_id'] == uid;
      final other = isUser1 ? m['user2'] : m['user1'];
      return MatchModel.fromJson({...m, 'other_user': other});
    }).toList();
  }

  Future<List<MessageModel>> getMessages(String matchId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: true);

    // Okunmamışları okundu yap
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('match_id', matchId)
        .neq('sender_id', uid)
        .eq('is_read', false);

    return (response as List)
        .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage({
    required String matchId,
    required String content,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final response = await _client.from('messages').insert({
      'match_id': matchId,
      'sender_id': uid,
      'content': content,
    }).select().single();
    return MessageModel.fromJson(response as Map<String, dynamic>);
  }

  Stream<List<MessageModel>> messageStream(String matchId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at')
        .map((rows) => rows.map(MessageModel.fromJson).toList());
  }
}
