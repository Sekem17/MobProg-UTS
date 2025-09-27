import 'package:flutter/material.dart';

class PostPage extends StatefulWidget {

  final String name;
  final String username;

  const PostPage({
    required this.name,
    required this.username,
    super.key
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Post Baru'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              final content = _postController.text.trim();
              if (content.isNotEmpty) {
                Navigator.of(context).pop(content);
              }
            },
            child: const Text(
              'Post',
              style: TextStyle(fontSize: 18, color: Colors.deepPurple),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _postController,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "Apa yang sedang Anda pikirkan?",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}