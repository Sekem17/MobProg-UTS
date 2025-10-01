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
  // Controller BARU untuk Judul
  final TextEditingController _titleController = TextEditingController(); 
  final TextEditingController _postController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose(); // Dispose controller baru
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
              final title = _titleController.text.trim();
              final content = _postController.text.trim();
              
              if (content.isNotEmpty) {
                // KEMBALIKAN MAP berisi Judul dan Isi
                Navigator.of(context).pop({"title": title, "content": content});
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
        child: Column( // Gunakan Column untuk menampung kedua input
          children: [
            // INPUT JUDUL BARU
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Judul",
                border: InputBorder.none,
                // Tambahkan garis bawah untuk pemisah visual
                contentPadding: EdgeInsets.symmetric(vertical: 10), 
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              maxLines: 1,
            ),
            const Divider(height: 1), // Garis pemisah
            
            // INPUT ISI POST LAMA
            Expanded(
              child: TextField(
                controller: _postController,
                autofocus: true,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Silahkan tuliskan yang ingin anda tulis :)",
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}