import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationStorage {
  static String _getNotifKey(String username) => 'notifications_list_$username';
  static Future<void> addNotification(
    Map<String, dynamic> notification,
    String recipientUsername,
  ) async {
    if (recipientUsername == 'guest') return;

    final prefs = await SharedPreferences.getInstance();
    final key = _getNotifKey(recipientUsername);

    final existingJson = prefs.getString(key);
    List<Map<String, dynamic>> notifications = [];

    if (existingJson != null) {
      final List decoded = json.decode(existingJson);
      notifications = decoded.map((e) => e as Map<String, dynamic>).toList();
    }

    notification["timestamp"] = DateTime.now().toIso8601String();
    notifications.insert(0, notification);

    if (notifications.length > 50) {
      notifications = notifications.sublist(0, 50);
    }

    await prefs.setString(key, json.encode(notifications));
  }

  static Future<List<Map<String, dynamic>>> loadNotifications(
    String currentUsername,
  ) async {
    if (currentUsername == 'guest') return [];

    final prefs = await SharedPreferences.getInstance();
    final key = _getNotifKey(currentUsername);

    final existingJson = prefs.getString(key);
    if (existingJson != null) {
      final List decoded = json.decode(existingJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  static Future<void> deleteNotifications(String currentUsername) async {
    if (currentUsername == 'guest') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getNotifKey(currentUsername));
  }
}
