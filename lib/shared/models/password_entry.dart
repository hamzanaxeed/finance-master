import 'package:uuid/uuid.dart';

class PasswordEntry {
  final String id;
  final String appName;
  final String username;
  final String email;
  final String password;
  final String? note;
  final DateTime createdAt;

  PasswordEntry({
    String? id,
    required this.appName,
    required this.username,
    required this.email,
    required this.password,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'appName': appName,
        'username': username,
        'email': email,
        'password': password,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
        id: json['id'] as String?,
        appName: json['appName'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

