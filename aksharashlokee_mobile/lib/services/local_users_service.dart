import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/user.dart';

class LocalUsersService {
  static const String _assetPath = 'assets/users.json';
  static List<User>? _cachedUsers;

  static Future<List<User>> getAllUsers() async {
    if (_cachedUsers != null) return _cachedUsers!;

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final dynamic data = json.decode(jsonString);

      // File structure is an array with a table entry containing users data.
      List<User> users = [];
      if (data is List) {
        final tableEntry = data.firstWhere(
          (e) => e is Map && e['type'] == 'table' && e['name'] == 'users',
          orElse: () => null,
        );
        if (tableEntry is Map && tableEntry['data'] is List) {
          final List rawUsers = tableEntry['data'];
          users = rawUsers
              .map((u) {
                if (u is Map<String, dynamic>) {
                  return User(
                    id: (u['_id'] ?? u['id'] ?? '').toString(),
                    name: (u['name'] ?? '').toString(),
                    email: (u['email'] ?? '').toString(),
                    role: (u['role'] ?? '').toString(),
                  );
                }
                return null;
              })
              .whereType<User>()
              .toList();
        }
      }

      _cachedUsers = users;
      return _cachedUsers!;
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  static Future<List<User>> getEditors(
      {bool includeAdminsAsEditors = false}) async {
    final users = await getAllUsers();
    if (includeAdminsAsEditors) {
      return users.where((u) => u.isEditor).toList();
    }
    return users.where((u) => u.role == 'editor').toList();
  }

  static void clearCache() {
    _cachedUsers = null;
  }
}
