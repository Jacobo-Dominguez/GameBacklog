class User {
  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final String? avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    this.avatarUrl,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? passwordHash,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
