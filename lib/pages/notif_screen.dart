import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medsos/storage/notif_storage.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _currentUsername = 'guest';
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndNotifications();
  }

  String _formatTime(String timestamp) {
    try {
      final notifTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(notifTime);

      if (difference.inMinutes < 1) return "Baru saja";
      if (difference.inHours < 1) return "${difference.inMinutes} menit lalu";
      if (difference.inDays < 1) return "${difference.inHours} jam lalu";
      return DateFormat('d MMM yyyy').format(notifTime);
    } catch (e) {
      return "Waktu tidak valid";
    }
  }

  Future<void> _loadUserAndNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('current_user'); // Tanpa '@'

    if (username != null) {
      _currentUsername = username;
      final loadedNotifs = await NotificationStorage.loadNotifications(
        _currentUsername,
      );

      setState(() {
        _notifications = loadedNotifs;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearNotifications() async {
    if (_currentUsername == 'guest') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus semua?'), 
          content: const Text(
            'Anda yakin ingin menghapus semua notifikasi?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), 
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), 
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await NotificationStorage.deleteNotifications(_currentUsername);
      setState(() {
        _notifications = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua notifikasi telah dihapus.")),
      );
    }
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
      case 'reply':
        return Icons.chat_bubble;
      case 'share':
        return Icons.share;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'follow':
        return Colors.blue;
      default:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_currentUsername == 'guest') {
      content = const Center(
        child: Text("Silahkan login untuk melihat notifikasi Anda."),
      );
    } else if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_notifications.isEmpty) {
      content = Center(
        child: Text("Tidak ada notifikasi untuk @$_currentUsername."),
      );
    } else {
      content = ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final sender = notif['sender'] ?? '@unknown';
          final message = notif['message'] ?? 'Melakukan sesuatu.';
          final time = _formatTime(notif['timestamp']);
          final type = notif['type'] ?? 'default';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getNotifColor(type),
              child: Icon(_getNotifIcon(type), color: Colors.white, size: 20),
            ),
            title: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(
                    text: '$sender ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: message, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            subtitle: Text(
              time,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Notifikasi dari $sender: $message")),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: _clearNotifications,
              tooltip: "Hapus semua notifikasi",
            ),
        ],
      ),
      body: content,
    );
  }
}