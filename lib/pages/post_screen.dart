import 'package:flutter/material.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _postController = TextEditingController();

  // Simulasi daftar postingan
  final List<String> _posts = [];

  void _addPost() {
    if (_postController.text.isNotEmpty) {
      setState(() {
        _posts.insert(0, _postController.text); // tambah ke atas list
        _postController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Form untuk membuat postingan
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _postController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "What's happening?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addPost,
            child: const Text("Post"),
          ),
          const Divider(),
          // Daftar postingan
          Expanded(
            child: _posts.isEmpty
                ? const Center(child: Text("Belum ada postingan"))
                : ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(_posts[index]),
                          subtitle: Text(
                            "Just now",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
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
