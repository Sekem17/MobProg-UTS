import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medsos/storage/chat_storage.dart';
import 'package:medsos/fitur/fitur_chat.dart';
import 'package:medsos/widget/avatar_widget.dart';

class DmPage extends StatefulWidget {
  const DmPage({super.key});

  @override
  State<DmPage> createState() => _DmPageState();
}

class _DmPageState extends State<DmPage> {
  String _currentUsername = "";
  List<Map<String, String>> _dmEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDmData();
  }

  Future<void> _loadDmData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('current_user'); 

    if (currentUsername == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _currentUsername = currentUsername;

    final allKeys = prefs.getKeys();
    List<Map<String, String>> potentialDmUsers = [];

    final userKeys = allKeys
        .where((key) => key.startsWith('user_') && key != 'current_user')
        .toList();

    for (var key in userKeys) {
      final username = key.substring(5);
      final name = prefs.getString('name_$username');

      if (name != null) {
        final messages = await ChatStorage.loadMessages(
          currentUsername,
          username,
        );

        String lastMessage = "Mulai percakapan...";
        String time = "";

        if (messages.isNotEmpty) {
          final lastMsg = messages.last;
          lastMessage = lastMsg["content"] ?? "Pesan terhapus";

          final isLastMsgFromOther = lastMsg["sender"] != currentUsername;

          time = isLastMsgFromOther ? "Baru" : "";
        }

        potentialDmUsers.add({
          "username": "@$username",
          "name": name,
          "last_message": lastMessage,
          "time": time.isNotEmpty ? time : "",
        });
      }
    }

    potentialDmUsers.sort((a, b) => a["name"]!.compareTo(b["name"]!));

    setState(() {
      _dmEntries = potentialDmUsers;
      _isLoading = false;
    });
  }

  void _openChatRoom(BuildContext context, Map<String, String> dm) async {
    final otherUsername = dm["username"]!.substring(1);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          currentUser: _currentUsername,
          otherUser: otherUsername,
          name: dm["name"]!,
          username: dm["username"]!,
        ),
      ),
    );

    setState(() {
      _isLoading = true;
    });
    _loadDmData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Direct Messages'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_dmEntries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Direct Messages'), centerTitle: true),
        body: const Center(child: Text("Belum ada user terdaftar.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Direct Messages'), centerTitle: true),
      body: ListView.builder(
        itemCount: _dmEntries.length,
        itemBuilder: (context, index) {
          final dm = _dmEntries[index];
          final isNewMessage = dm["time"] == "Baru";

          final dmUserWithoutAt = dm["username"]!.substring(1);
          final isMe = dmUserWithoutAt == _currentUsername;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: ListTile(
              leading: UserAvatar(username: dmUserWithoutAt, radius: 24),
              title: Row(
                children: [
                  Text(
                    dm["name"]!,
                    style: TextStyle(
                      fontWeight: isNewMessage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),

                  if (isMe)
                    const Padding(
                      padding: EdgeInsets.only(left: 6.0),
                      child: Text(
                        '(me)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(width: 6),
                  Text(
                    dm["username"]!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  if (dm["time"]!.isNotEmpty)
                    Text(
                      dm["time"]!,
                      style: TextStyle(
                        color: isNewMessage ? Colors.deepPurple : Colors.grey,
                        fontSize: 12,
                        fontWeight: isNewMessage
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  dm["last_message"]!,
                  style: isNewMessage
                      ? const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        )
                      : const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onTap: () => _openChatRoom(context, dm),
            ),
          );
        },
      ),
    );
  }
}