// lib/pages/home_screen.dart

import 'package:flutter/material.dart';
import 'post_screen.dart';
import 'package:medsos/storage/post_storage.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _posts = [];

  final _currentUser = {
    "name": "Nama Anda",
    "username": "@anda",
    "avatar": "assets/gambar/avatarpp.jpg",
  };

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final loadedPosts = await PostStorage.loadPosts();
    setState(() {
      _posts = loadedPosts;
    });
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
        title: const Text('Xwritter - Timeline'),
        centerTitle: true,
        actions: [
          // Tombol hapus data
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await PostStorage.deletePosts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Semua post telah dihapus.")),
              );
              _loadPosts(); // Muat ulang tampilan setelah menghapus
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(post["avatar"]!),
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
              trailing: const Icon(Icons.more_vert),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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