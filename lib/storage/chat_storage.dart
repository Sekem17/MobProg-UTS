import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatStorage {
  static String _getChatKey(String userA, String userB) {
    final users = [userA, userB];
    users.sort();
    return 'chat_${users.join('_')}';
  }

  static Future<List<Map<String, String>>> loadMessages(
    String userA,
    String userB,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getChatKey(userA, userB);
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => Map<String, String>.from(item as Map))
          .toList();
    } catch (e) {
      print('Error decoding messages for $key: $e');
      return [];
    }
  }

  static Future<void> saveMessages(
    String userA,
    String userB,
    List<Map<String, String>> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getChatKey(userA, userB);
    final jsonString = json.encode(messages);
    await prefs.setString(key, jsonString);
  }

  static Future<void> clearAllChats() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final chatKeys = allKeys.where((key) => key.startsWith('chat_')).toList();

    for (var key in chatKeys) {
      await prefs.remove(key);
    }
  }
}
