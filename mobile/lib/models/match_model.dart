class MatchUser {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const MatchUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory MatchUser.fromJson(Map<String, dynamic> json) {
    return MatchUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class MatchModel {
  final String id;
  final String status;
  final String? capsuleId;
  final DateTime createdAt;
  final MatchUser otherUser;

  const MatchModel({
    required this.id,
    required this.status,
    this.capsuleId,
    required this.createdAt,
    required this.otherUser,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      status: json['status'] as String,
      capsuleId: json['capsule_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      otherUser: MatchUser.fromJson(json['other_user'] as Map<String, dynamic>),
    );
  }
}

class MessageModel {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
