import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // contoh data notifikasi
    final List<Map<String, String>> notifications = [
      {"user": "Andi", "message": "Menyukai tweet kamu", "time": "2m"},
      {"user": "Budi", "message": "Mengomentari postingan kamu", "time": "10m"},
      {"user": "Citra", "message": "Mulai mengikuti kamu", "time": "30m"},
      {"user": "Dewi", "message": "Menyebut kamu dalam sebuah tweet", "time": "1h"},
      {"user": "Eko", "message": "Menyukai komentar kamu", "time": "2h"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.notifications, color: Colors.white),
            ),
            title: Text(
              "${notif['user']} ${notif['message']}",
              style: const TextStyle(fontSize: 15),
            ),
            subtitle: Text(
              notif['time']!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Klik notifikasi dari ${notif['user']}")),
              );
            },
          );
        },
      ),
    );
  }
}