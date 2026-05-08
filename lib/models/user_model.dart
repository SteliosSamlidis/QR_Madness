enum UserRole { admin, employee }

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.employee,
  });

  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.employee,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    if (displayName != null) 'displayName': displayName,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'role': role.name,
  };
}
