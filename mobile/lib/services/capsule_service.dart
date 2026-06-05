import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/capsule_model.dart';

class CapsuleService {
  final _client = Supabase.instance.client;

  Future<List<CapsuleModel>> getNearbyCapsules({
    required double lat,
    required double lon,
  }) async {
    final response = await _client.rpc('get_nearby_capsules', params: {
      'user_lat': lat,
      'user_lon': lon,
      'limit_count': 50,
    });

    final uid = _client.auth.currentUser?.id;
    return (response as List)
        .where((c) => c['user_id'] != uid)
        .map((c) => CapsuleModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<String> createCapsule({
    required double lat,
    required double lon,
    required bool isIndoor,
    required String contentText,
    String? songName,
    String? artistName,
    String? mood,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final response = await _client.from('capsules').insert({
      'user_id': uid,
      'location': 'SRID=4326;POINT($lon $lat)',
      'is_indoor': isIndoor,
      'content_text': contentText,
      'song_name': songName,
      'artist_name': artistName,
      'mood': mood,
    }).select('id').single();
    return response['id'] as String;
  }

  Future<void> unlockCapsule({
    required String capsuleId,
    String? replyText,
  }) async {
    final uid = _client.auth.currentUser!.id;

    final existing = await _client
        .from('capsule_unlocks')
        .select('id')
        .eq('capsule_id', capsuleId)
        .eq('opener_id', uid)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('capsule_unlocks')
          .update({'reply_text': replyText})
          .eq('id', existing['id'] as String);
    } else {
      await _client.from('capsule_unlocks').insert({
        'capsule_id': capsuleId,
        'opener_id': uid,
        'reply_text': replyText,
      });
    }
  }

  Future<List<CapsuleModel>> getMyCapsules() async {
    final uid = _client.auth.currentUser!.id;
    final response = await _client
        .from('capsules')
        .select()
        .eq('user_id', uid)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((c) => CapsuleModel.fromJson({...c, 'distance_meters': 0.0}))
        .toList();
  }
}
