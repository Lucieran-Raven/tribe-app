class UserModel {
  final String userId;
  final String email;
  final String? handle;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.email,
    this.handle,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get hasCompletedOnboarding => handle != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      handle: json['handle'] as String?,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'handle': handle,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? handle,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}