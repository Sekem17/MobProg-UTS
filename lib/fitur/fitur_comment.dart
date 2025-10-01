import 'package:flutter/material.dart';

// Definisi type alias untuk kemudahan (opsional)
typedef CommentData = Map<String, dynamic>;
typedef TimeFormatter = String Function(String timestamp);
typedef PostCommentCallback = void Function(String content);

class CommentSection extends StatelessWidget {
  final List<CommentData> comments;
  final TextEditingController commentController;
  final PostCommentCallback onPostComment;
  final TimeFormatter formatTimeAgo;
  final String currentUsername;
  final Function(int, int) onDeleteComment; // (postIndex, commentIndex)
  final int postIndex; // Index dari post di list _posts HomePage

  const CommentSection({
    super.key,
    required this.comments,
    required this.commentController,
    required this.onPostComment,
    required this.formatTimeAgo,
    required this.currentUsername,
    required this.onDeleteComment,
    required this.postIndex,
  });

  // Widget untuk menampilkan 1 komentar
  Widget _buildCommentTile(CommentData comment, int commentIndex, BuildContext context) {
    // Logika ini harus sama dengan yang ada di PostInteractionWidget (jika Anda memisahkannya)
    final bool isCommentOwner = comment["username"] == currentUsername;
    final bool isPostOwner = false; // Harus dilewatkan jika ingin pemilik post bisa hapus
    final bool canDelete = isCommentOwner || isPostOwner; 

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade300,
            child: Text(comment["name"]?[0] ?? '?', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                    children: <TextSpan>[
                      TextSpan(
                          text: '${comment["name"]!} ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: comment["content"]!),
                    ],
                  ),
                ),
                Text(
                  formatTimeAgo(comment["timestamp"]!),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          
          // Tombol Hapus Komentar dalam Pop-up Menu (Titik Tiga)
          if (canDelete)
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'delete_comment') {
                  // Panggil callback hapus dengan postIndex dan commentIndex
                  onDeleteComment(postIndex, commentIndex); 
                }
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete_comment',
                      child: Text(
                        'Hapus Komentar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              padding: EdgeInsets.zero, 
              offset: const Offset(0, 20),
            ),
        ],
      ),
    );
  }

  // Widget Form Input Komentar
  Widget _buildCommentInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(radius: 18, child: Text(currentUsername.substring(1, 2).toUpperCase())),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: "Tambahkan komentar...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () {
              // Panggil callback untuk memposting komentar
              onPostComment(commentController.text);
              FocusScope.of(context).unfocus(); // Tutup keyboard setelah kirim
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // Tampilkan Komentar (Semua atau 2 Teratas - diasumsikan fitur full comments sudah dihandle di level HomePage/PostInteractionWidget)
    // Untuk kesederhanaan, kita tampilkan semua yang dilewatkan ke widget ini.
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        
        // Daftar Komentar
        ...comments.asMap().entries
            .map((entry) => _buildCommentTile(entry.value, entry.key, context))
            .toList(),

        // Tombol Lihat Semua (diasumsikan sudah ditangani di PostInteractionWidget)

        // Input Komentar
        _buildCommentInput(context),
      ],
    );
  }
}