class RantModel {
  final String rantId;
  final String userId;
  final String handle;
  final String? avatarUrl;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final int replyCount;
  final int karma;
  final bool isVisible;
  final List<String> voterIds;

  RantModel({
    required this.rantId,
    required this.userId,
    required this.handle,
    this.avatarUrl,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    this.replyCount = 0,
    this.karma = 0,
    this.isVisible = true,
    this.voterIds = const [],
  });

  factory RantModel.fromJson(Map<String, dynamic> json, {String? rantId}) {
    return RantModel(
      rantId: rantId ?? json['rantId'] as String,
      userId: json['userId'] as String,
      handle: json['handle'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      replyCount: json['replyCount'] as int? ?? 0,
      karma: json['karma'] as int? ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      voterIds: List<String>.from(json['voterIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rantId': rantId,
      'userId': userId,
      'handle': handle,
      'avatarUrl': avatarUrl,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'replyCount': replyCount,
      'karma': karma,
      'isVisible': isVisible,
      'voterIds': voterIds,
    };
  }

  RantModel copyWith({
    String? rantId,
    String? userId,
    String? handle,
    String? avatarUrl,
    String? content,
    String? imageUrl,
    DateTime? timestamp,
    int? replyCount,
    int? karma,
    bool? isVisible,
    List<String>? voterIds,
  }) {
    return RantModel(
      rantId: rantId ?? this.rantId,
      userId: userId ?? this.userId,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      replyCount: replyCount ?? this.replyCount,
      karma: karma ?? this.karma,
      isVisible: isVisible ?? this.isVisible,
      voterIds: voterIds ?? this.voterIds,
    );
  }
}
