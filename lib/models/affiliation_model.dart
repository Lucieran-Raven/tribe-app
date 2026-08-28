class AffiliationModel {
  final String id;
  final String name;
  final String type; // 'university', 'city', 'interest'
  final bool verified;

  const AffiliationModel({
    required this.id,
    required this.name,
    required this.type,
    this.verified = false,
  });

  factory AffiliationModel.fromJson(Map<String, dynamic> json) {
    return AffiliationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'verified': verified,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  AffiliationModel copyWith({
    String? id,
    String? name,
    String? type,
    bool? verified,
  }) {
    return AffiliationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      verified: verified ?? this.verified,
    );
  }
}
