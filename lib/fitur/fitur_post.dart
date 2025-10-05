import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PostInteractionWidget extends StatelessWidget {
  final Map<String, dynamic> post;
  final Map<String, String> currentUser;
  final int index;
  final bool isCommentExpanded;
  final bool isFullComments;
  final bool isPostOwner;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final List<Map<String, dynamic>> commentsList;
  final String Function(String timestamp) formatTimeAgo;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleCommentSection;
  final VoidCallback onShare;
  final VoidCallback onToggleFullComments;
  final VoidCallback onAddComment;
  final Function(int, int) onDeleteComment;
  final Function(String parentUsername, String replyContent) onReply;
  final TextEditingController commentController;

  const PostInteractionWidget({
    super.key,
    required this.post,
    required this.currentUser,
    required this.index,
    required this.isCommentExpanded,
    required this.isFullComments,
    required this.isPostOwner,
    required this.onToggleLike,
    required this.onToggleCommentSection,
    required this.onShare,
    required this.onAddComment,
    required this.onToggleFullComments,
    required this.onDeleteComment,
    required this.onReply,
    required this.commentController,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.commentsList,
    required this.formatTimeAgo,
  });

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "N/A";
    final postTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) return "Sekarang";
    if (difference.inHours < 1) return "${difference.inMinutes}m";
    if (difference.inDays < 1) return "${difference.inHours}j";
    return DateFormat('d MMM').format(postTime);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String count,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(count, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showReplyInput(
    BuildContext context,
    String parentUsername,
    String parentName,
  ) {
    if (currentUser["username"] == "@guest") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login untuk membalas komentar.")),
      );
      return;
    }

    final TextEditingController replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Membalas ${parentName} (${parentUsername})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "Ketik balasan...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.deepPurple),
                      onPressed: () {
                        final content = replyController.text.trim();
                        if (content.isNotEmpty) {
                          Navigator.pop(context);
                          onReply(parentUsername, content);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentTile(
    Map<String, dynamic> comment,
    int commentIndex,
    BuildContext context,
  ) {
    final String commentUsername = comment["username"].toString();
    final String commentName = comment["name"].toString();
    final String commentContent = comment["content"].toString();
    final String commentTimestamp = comment["timestamp"].toString();

    final bool isCommentOwner = commentUsername == currentUser["username"];
    final bool canDelete = isCommentOwner || isPostOwner;

    final bool isReply =
        comment.containsKey("reply_to_user") &&
        comment["reply_to_user"] != null;

    List<String> contentParts = commentContent.split(' ');
    String userTag = isReply ? contentParts.first : '';
    String actualContent = isReply
        ? contentParts.skip(1).join(' ')
        : commentContent;

    return GestureDetector(
      onTap: () {
        if (commentUsername != currentUser["username"]) {
          _showReplyInput(context, commentUsername, commentName);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 12, child: Text(commentName[0])),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        TextSpan(
                          text: '$commentName ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (isReply)
                          TextSpan(
                            text: '$userTag ',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        TextSpan(
                          text: actualContent,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(commentTimestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),

            if (canDelete)
              PopupMenuButton<String>(
                onSelected: (String result) {
                  if (result == 'delete_comment') {
                    onDeleteComment(index, commentIndex);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int commentsToShowCount = isFullComments ? commentsList.length : 2;
    final commentsToShow = commentsList
        .asMap()
        .entries
        .take(commentsToShowCount)
        .map((entry) => _buildCommentTile(entry.value, entry.key, context))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 10,
            left: 16,
            right: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post["title"] != null && post["title"]!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    post["title"]!.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

              Text(
                post["content"] is String ? post["content"]! : '',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
                count: likeCount.toString(),
                onTap: onToggleLike,
              ),
              const SizedBox(width: 10),

              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                color: Colors.grey,
                count: commentCount.toString(),
                onTap: onToggleCommentSection,
              ),
              const SizedBox(width: 10),

              _buildActionButton(
                icon: Icons.repeat,
                color: Colors.grey,
                count: shareCount.toString(),
                onTap: onShare,
              ),
            ],
          ),
        ),

        if (isCommentExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                  child: Text(
                    "Komentar:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...commentsToShow,
                if (commentCount > 2)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      top: 4.0,
                      bottom: 8.0,
                    ),
                    child: GestureDetector(
                      onTap: onToggleFullComments,
                      child: Text(
                        isFullComments
                            ? "Sembunyikan komentar"
                            : "...lihat semua komentar (${commentCount - 2} lainnya)",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),

                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Text(currentUser["name"]![0]),
                      ),
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
                        icon: const Icon(Icons.send, color: Colors.deepPurple),
                        onPressed: onAddComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class FiturPost {
  static Widget buildPostItem(
    BuildContext context,
    Map<String, dynamic> post,
    int index,
    Function(int) onDelete,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        leading: CircleAvatar(child: Text(post['name']?[0] ?? 'P')),
        title: Text(
          post['name'] ?? 'Pengguna',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['username'] ?? '@user',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              (post['title']?.isNotEmpty == true ? post['title']! + '\n' : '') +
                  (post['content'] ?? 'No Content'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
