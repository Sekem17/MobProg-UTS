import 'package:flutter/material.dart';
import 'post_screen.dart';
import 'package:medsos/storage/post_storage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _posts = [];

  Map<String, String> _currentUser = {
    "name": "Pengguna",
    "username": "@guest",
    "avatar": "assets/gambar/avatarpp.jpg",
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPosts();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('current_user');

    if (currentUsername != null) {
      final name = prefs.getString('name_$currentUsername') ?? 'Nama Anda';

      setState(() {
        _currentUser = {
          "name": name,
          "username": "@$currentUsername",
          "avatar": "assets/gambar/avatarpp.jpg",
        };
      });
    }
  }

  Future<void> _loadPosts() async {
    final loadedPosts = await PostStorage.loadPosts();
    setState(() {
      _posts = loadedPosts;
    });
  }

  Future<void> _deletePost(int index) async {
    setState(() {
      _posts.removeAt(index);
    });

    await PostStorage.savePosts(_posts);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Post telah dihapus.")));
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) {
      return "N/A";
    }
    final postTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) {
      return "Sekarang";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}j";
    } else {
      return DateFormat('d MMM').format(postTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YAPP'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await PostStorage.deletePosts();

              setState(() {
                _posts = [];
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Semua post telah dihapus.")),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final isCurrentUserPost =
              post["username"] == _currentUser["username"];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: post["avatar"] is String
                    ? AssetImage(post["avatar"]!)
                    : null,
              ),
              title: Row(
                children: [
                  Text(
                    post["name"]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    post["username"]!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "· ${post['timestamp'] != null ? _formatTime(post['timestamp']!) : 'N/A'}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(post["content"] is String ? post["content"]! : ''),
              ),

              trailing: isCurrentUserPost
                  ? PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'delete') {
                          _deletePost(index);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Hapus Post',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                      icon: const Icon(Icons.more_vert),
                    )
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_currentUser["username"] == "@guest") {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Data pengguna belum dimuat, coba lagi."),
              ),
            );
            return;
          }

          final newPostContent = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostPage(
                name: _currentUser["name"]!,
                username: _currentUser["username"]!,
              ),
            ),
          );

          if (newPostContent != null) {
            final newPost = {
              "username": _currentUser["username"]!,
              "name": _currentUser["name"]!,
              "content": newPostContent,
              "timestamp": DateTime.now().toIso8601String(),
              "avatar": _currentUser["avatar"]!,
            };

            setState(() {
              _posts.insert(0, newPost);
            });
            await PostStorage.savePosts(_posts);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
