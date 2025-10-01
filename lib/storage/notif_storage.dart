// storage/notification_storage.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationStorage {
    
    // Key sekarang bergantung pada username
    static String _getNotifKey(String username) => 'notifications_list_$username';

    // FUNGSI BARU: Tambahkan username penerima
    static Future<void> addNotification(
        Map<String, dynamic> notification, 
        String recipientUsername // Penerima Notifikasi
    ) async {
        if (recipientUsername == 'guest') return;
        
        final prefs = await SharedPreferences.getInstance();
        final key = _getNotifKey(recipientUsername); // Gunakan key spesifik user
        
        final existingJson = prefs.getString(key);
        List<Map<String, dynamic>> notifications = [];
        
        if (existingJson != null) {
            final List decoded = json.decode(existingJson);
            notifications = decoded.map((e) => e as Map<String, dynamic>).toList();
        }
        
        // Tambahkan timestamp dan ikon/type jika belum ada
        notification["timestamp"] = DateTime.now().toIso8601String();
        notifications.insert(0, notification); // Tambahkan di awal
        
        // Batasi jumlah notifikasi
        if (notifications.length > 50) {
            notifications = notifications.sublist(0, 50);
        }

        await prefs.setString(key, json.encode(notifications));
    }

    // FUNGSI BARU: Membutuhkan username untuk dimuat
    static Future<List<Map<String, dynamic>>> loadNotifications(String currentUsername) async {
        if (currentUsername == 'guest') return [];
        
        final prefs = await SharedPreferences.getInstance();
        final key = _getNotifKey(currentUsername); // Gunakan key spesifik user
        
        final existingJson = prefs.getString(key);
        if (existingJson != null) {
            final List decoded = json.decode(existingJson);
            // Pastikan setiap item adalah Map<String, dynamic>
            return decoded.map((e) => e as Map<String, dynamic>).toList();
        }
        return [];
    }

    // Tambahkan fungsi delete
    static Future<void> deleteNotifications(String currentUsername) async {
        if (currentUsername == 'guest') return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_getNotifKey(currentUsername));
    }
}