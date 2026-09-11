class ReplyModel {
  final String replyId;
  final String rantId;
  final String userId;
  final String handle;
  final String? avatarUrl;
  final String content;
  final DateTime timestamp;
  final String? parentId;
  final int karma;
  final List<String> voterIds;

  ReplyModel({
    required this.replyId,
    required this.rantId,
    required this.userId,
    required this.handle,
    this.avatarUrl,
    required this.content,
    required this.timestamp,
    this.parentId,
    this.karma = 0,
    this.voterIds = const [],
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json, {String? replyId}) {
    return ReplyModel(
      replyId: replyId ?? json['replyId'] as String,
      rantId: json['rantId'] as String,
      userId: json['userId'] as String,
      handle: json['handle'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      parentId: json['parentId'] as String?,
      karma: json['karma'] as int? ?? 0,
      voterIds: List<String>.from(json['voterIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'replyId': replyId,
      'rantId': rantId,
      'userId': userId,
      'handle': handle,
      'avatarUrl': avatarUrl,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'parentId': parentId,
      'karma': karma,
      'voterIds': voterIds,
    };
  }

  ReplyModel copyWith({
    String? replyId,
    String? rantId,
    String? userId,
    String? handle,
    String? avatarUrl,
    String? content,
    DateTime? timestamp,
    String? parentId,
    int? karma,
    List<String>? voterIds,
  }) {
    return ReplyModel(
      replyId: replyId ?? this.replyId,
      rantId: rantId ?? this.rantId,
      userId: userId ?? this.userId,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      parentId: parentId ?? this.parentId,
      karma: karma ?? this.karma,
      voterIds: voterIds ?? this.voterIds,
    );
  }
}
