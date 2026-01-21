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
}
