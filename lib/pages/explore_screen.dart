import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medsos/storage/notif_storage.dart';
import 'package:medsos/fitur/fitur_chat.dart';
import 'package:medsos/widget/avatar_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, String>> _allAccounts = [];
  bool _isLoading = true;
  String query = "";

  Map<String, bool> _followingStatus = {};
  String _currentUsername = "";

  static const String _followingKey = 'user_following_list';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadFollowingStatus() async {
    if (_currentUsername == 'guest') return;
    final prefs = await SharedPreferences.getInstance();
    final List<String> followingList =
        prefs.getStringList('${_followingKey}_$_currentUsername') ?? [];

    setState(() {
      _followingStatus = {for (var username in followingList) username: true};
    });
  }

  Future<void> _saveFollowingStatus() async {
    if (_currentUsername == 'guest') return;
    final prefs = await SharedPreferences.getInstance();

    final List<String> followingList = _followingStatus.keys
        .where((username) => _followingStatus[username] == true)
        .toList();

    await prefs.setStringList(
      '${_followingKey}_$_currentUsername',
      followingList,
    );
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('current_user');
    setState(() {
      _currentUsername = currentUsername ?? 'guest';
    });
    await _loadRegisteredAccounts(currentUsername);
    await _loadFollowingStatus();
  }

  Future<void> _loadRegisteredAccounts(String? currentUsername) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    List<Map<String, String>> loadedAccounts = [];

    final userKeys = allKeys
        .where((key) => key.startsWith('user_') && key != 'current_user')
        .toList();

    for (var key in userKeys) {
      final username = key.substring(5);
      final name = prefs.getString('name_$username');

      if (name != null && username.isNotEmpty) {
        if (username != currentUsername) {
          loadedAccounts.add({"name": name, "username": "@$username"});
        }
      }
    }

    loadedAccounts.sort((a, b) => a["name"]!.compareTo(b["name"]!));

    setState(() {
      _allAccounts = loadedAccounts;
      _isLoading = false;
    });
  }

  void _toggleFollow(String username, String name) async {
    if (_currentUsername == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda harus login untuk mengikuti akun.")),
      );
      return;
    }

    final bool currentlyFollowing = _followingStatus[username] ?? false;

    setState(() {
      _followingStatus[username] = !currentlyFollowing;
    });

    final isNowFollowing = _followingStatus[username]!;

    await _saveFollowingStatus();

    await NotificationStorage.addNotification({
      "type": "follow",
      "sender": "@$_currentUsername",
      "message": "Mulai mengikuti Anda.",
    }, username.substring(1));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNowFollowing
              ? "Anda mengikuti $name"
              : "Anda berhenti mengikuti $name",
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openDM(String otherUsername, String otherName) {
    if (_currentUsername == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda harus login untuk mengirim pesan.")),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          currentUser: _currentUsername,
          otherUser: otherUsername.substring(1),
          name: otherName,
          username: otherUsername,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = _allAccounts.where((account) {
      final name = account["name"]!.toLowerCase();
      final username = account["username"]!.toLowerCase();
      final input = query.toLowerCase();
      return name.contains(input) || username.contains(input);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Explore"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari akun...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),

          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Expanded(
                  child: filteredAccounts.isEmpty
                      ? Center(
                          child: Text(
                            query.isEmpty
                                ? "Belum ada akun yang terdaftar."
                                : "Akun tidak ditemukan",
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredAccounts.length,
                          itemBuilder: (context, index) {
                            final account = filteredAccounts[index];
                            final username = account["username"]!;
                            final name = account["name"]!;

                            final isFollowing =
                                _followingStatus[username] ?? false;

                            return ListTile(
                              leading: UserAvatar(
                                username: username.substring(1),
                                radius: 24,
                              ),
                              title: Text(name),
                              subtitle: Text(username),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.message_outlined,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _openDM(username, name),
                                  ),
                                  const SizedBox(width: 8),

                                  SizedBox(
                                    width: 100,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _toggleFollow(username, name),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing
                                            ? Colors.grey.shade300
                                            : Colors.deepPurple,
                                        foregroundColor: isFollowing
                                            ? Colors.black
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                      ),
                                      child: Text(
                                        isFollowing ? "Following" : "Follow",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}