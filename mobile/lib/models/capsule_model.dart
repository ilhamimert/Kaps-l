class CapsuleModel {
  final String id;
  final String userId;
  final String contentText;
  final String? songName;
  final String? artistName;
  final String? mood;
  final bool isIndoor;
  final int unlockCount;
  final double distanceMeters;
  final DateTime createdAt;

  const CapsuleModel({
    required this.id,
    required this.userId,
    required this.contentText,
    this.songName,
    this.artistName,
    this.mood,
    required this.isIndoor,
    required this.unlockCount,
    required this.distanceMeters,
    required this.createdAt,
  });

  factory CapsuleModel.fromJson(Map<String, dynamic> json) {
    return CapsuleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentText: json['content_text'] as String,
      songName: json['song_name'] as String?,
      artistName: json['artist_name'] as String?,
      mood: json['mood'] as String?,
      isIndoor: json['is_indoor'] as bool? ?? false,
      unlockCount: json['unlock_count'] as int? ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get moodEmoji {
    const map = {
      'happy': '😊',
      'sad': '😢',
      'excited': '🎉',
      'calm': '😌',
      'nostalgic': '🌅',
      'romantic': '💕',
      'curious': '🤔',
    };
    return map[mood] ?? '💭';
  }

  String get distanceLabel {
    if (distanceMeters < 1) return '${distanceMeters.toStringAsFixed(1)} m';
    return '${(distanceMeters).toStringAsFixed(0)} m';
  }
}
