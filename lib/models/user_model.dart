import 'affiliation_model.dart';

class UserModel {
  final String userId;
  final String email;
  final String? handle;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final List<AffiliationModel> affiliations;

  UserModel({
    required this.userId,
    required this.email,
    this.handle,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.affiliations = const [],
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
      affiliations: (json['affiliations'] as List<dynamic>?)
          ?.map((item) => AffiliationModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
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
      'affiliations': affiliations.map((a) => a.toMap()).toList(),
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? handle,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    List<AffiliationModel>? affiliations,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      affiliations: affiliations ?? this.affiliations,
    );
  }
}