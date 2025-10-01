import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'post_screen.dart'; 
import 'package:medsos/storage/post_storage.dart';
import 'package:medsos/storage/notif_storage.dart'; 
import 'package:medsos/fitur/fitur_post.dart'; 

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
    "avatar": "G",
  };

  Set<int> _expandedCommentIndices = {};
  Set<int> _fullCommentsIndices = {}; 
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPosts();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  // --- Data & Utility Loading ---
  
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('current_user');

    if (currentUsername != null) {
      final name = prefs.getString('name_$currentUsername') ?? 'Nama Anda';

      setState(() {
        _currentUser = {
          "name": name,
          "username": "@$currentUsername",
          "avatar": name.substring(0, 1).toUpperCase(),
        };
      });
    }
  }

  Future<void> _loadPosts() async {
    final loadedPosts = await PostStorage.loadPosts();
    setState(() {
      _posts = loadedPosts.map((post) => {
        ...post,
        "title": post["title"] ?? "",
        "liked_by": (post["liked_by"] is List) 
            ? List<String>.from(post["liked_by"])
            : [],
        "comments_list": (post["comments_list"] is List) 
            ? List<Map<String, dynamic>>.from(post["comments_list"])
            : [], 
        "shared_by": (post["shared_by"] is List) 
            ? List<String>.from(post["shared_by"])
            : [],
      }).toList();
    });
  }

  String _formatTimeAgo(String timestamp) {
    try {
      final postTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(postTime);

      if (difference.inMinutes < 1) return "Baru saja";
      if (difference.inHours < 1) return "${difference.inMinutes}m";
      if (difference.inDays < 1) return "${difference.inHours}j";
      if (difference.inDays < 7) return "${difference.inDays}h";
      return DateFormat('d MMM yyyy').format(postTime);
    } catch (e) {
      return "N/A";
    }
  }
  
  // --- Post Actions & Notifikasi ---

  void _deletePost(int index) async {
    final postOwnerUsername = _posts[index]["username"]!;
    
    if (postOwnerUsername != _currentUser["username"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda hanya bisa menghapus post Anda sendiri.")),
      );
      return;
    }

    setState(() {
      _posts.removeAt(index);
    });
    await PostStorage.savePosts(_posts);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Postingan berhasil dihapus.")),
    );
  }

  void _toggleLike(int index) async {
    if (_currentUser["username"] == "@guest") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login untuk memberikan like!")),
      );
      return;
    }
    
    final currentUsernameWithoutAt = _currentUser["username"]!.substring(1); 
    final postOwnerUsernameWithoutAt = _posts[index]["username"]!.substring(1); 
    
    final likedBy = List<String>.from(_posts[index]["liked_by"] ?? []); 
    
    if (likedBy.contains(currentUsernameWithoutAt)) {
      likedBy.remove(currentUsernameWithoutAt);
    } else {
      likedBy.add(currentUsernameWithoutAt);
      
      // LOGIKA NOTIFIKASI
      if (currentUsernameWithoutAt != postOwnerUsernameWithoutAt) { 
        await NotificationStorage.addNotification({
            "type": "like",
            "sender": _currentUser["username"]!,
            "message": "Menyukai postingan Anda.",
        }, postOwnerUsernameWithoutAt); // Recipient
      }
    }

    setState(() {
      _posts[index]["liked_by"] = likedBy;
    });
    await PostStorage.savePosts(_posts);
  }

  void _toggleCommentSection(int index) {
    setState(() {
      if (_expandedCommentIndices.contains(index)) {
        _expandedCommentIndices.remove(index);
        _fullCommentsIndices.remove(index); 
      } else {
        _expandedCommentIndices.add(index);
      }
    });
  }
  
  void _toggleFullComments(int index) {
    setState(() {
      if (_fullCommentsIndices.contains(index)) {
        _fullCommentsIndices.remove(index);
      } else {
        _fullCommentsIndices.add(index);
      }
    });
  }

  void _addComment(int index) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
     if (_currentUser["username"] == "@guest") {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Login untuk berkomentar!")),
       );
       _commentController.clear();
       return;
     }

    final currentUsernameWithoutAt = _currentUser["username"]!.substring(1);
    final postOwnerUsernameWithoutAt = _posts[index]["username"]!.substring(1);

    final commentsList = List<Map<String, dynamic>>.from(_posts[index]["comments_list"] ?? []);
    
    final newComment = {
      "username": _currentUser["username"]!, 
      "name": _currentUser["name"]!,
      "content": content,
      "timestamp": DateTime.now().toIso8601String(),
    };
    
    setState(() {
      commentsList.insert(0, newComment);
      _posts[index]["comments_list"] = commentsList;
    });

    if (currentUsernameWithoutAt != postOwnerUsernameWithoutAt) { 
        await NotificationStorage.addNotification({
            "type": "comment",
            "sender": _currentUser["username"]!,
            "message": "Mengomentari postingan Anda.",
        }, postOwnerUsernameWithoutAt); // Recipient
    }

    _commentController.clear();
    FocusScope.of(context).unfocus(); 
    await PostStorage.savePosts(_posts);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Komentar berhasil ditambahkan!")),
    );
  }
  
  // FUNGSI BARU: Reply Komentar
  void _replyComment(int postIndex, String parentUsername, String replyContent) async {
    if (replyContent.isEmpty) return;
    if (_currentUser["username"] == "@guest") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login untuk membalas!")),);
      return;
    }

    final currentUsername = _currentUser["username"]!;
    final currentUsernameWithoutAt = currentUsername.substring(1);
    final postOwnerUsernameWithoutAt = _posts[postIndex]["username"]!.substring(1);
    final parentUsernameWithoutAt = parentUsername.substring(1); 

    final commentsList = List<Map<String, dynamic>>.from(_posts[postIndex]["comments_list"] ?? []);
    
    final newReply = {
      "username": currentUsername, 
      "name": _currentUser["name"]!,
      "content": "@${parentUsernameWithoutAt} $replyContent", 
      "timestamp": DateTime.now().toIso8601String(),
      "reply_to_user": parentUsername, 
    };
    
    setState(() {
      commentsList.insert(0, newReply);
      _posts[postIndex]["comments_list"] = commentsList;
    });

    // LOGIKA NOTIFIKASI: Kirim ke User yang Dibalas (Parent User)
    if (currentUsernameWithoutAt != parentUsernameWithoutAt) {
      await NotificationStorage.addNotification({
          "type": "reply",
          "sender": currentUsername,
          "message": "Mereply komentar Anda pada postingan...",
      }, parentUsernameWithoutAt); // Recipient
    }

    // LOGIKA NOTIFIKASI: Kirim ke Pemilik Post (jika berbeda dari yang me-reply atau dibalas)
    if (currentUsernameWithoutAt != postOwnerUsernameWithoutAt && parentUsernameWithoutAt != postOwnerUsernameWithoutAt) {
      await NotificationStorage.addNotification({
          "type": "comment",
          "sender": currentUsername,
          "message": "Mengomentari postingan Anda.",
      }, postOwnerUsernameWithoutAt); // Recipient
    }

    await PostStorage.savePosts(_posts);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Balasan berhasil diposting!")),
    );
  }

  void _deleteComment(int postIndex, int commentIndex) async {
    // ... (Fungsi tetap sama)
    setState(() {
      final List<Map<String, dynamic>> commentsList = 
          List<Map<String, dynamic>>.from(_posts[postIndex]["comments_list"] ?? []);
          
      if (commentIndex >= 0 && commentIndex < commentsList.length) {
        commentsList.removeAt(commentIndex);
        _posts[postIndex]["comments_list"] = commentsList;
      }
    });

    await PostStorage.savePosts(_posts);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Komentar berhasil dihapus.")),
    );
    if (_expandedCommentIndices.contains(postIndex)) {
      setState(() {});
    }
  }

  void _toggleShare(int index) async {
    if (_currentUser["username"] == "@guest") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login untuk berbagi!")),
      );
      return;
    }
    
    final currentUsernameWithoutAt = _currentUser["username"]!.substring(1); 
    final sharedBy = List<String>.from(_posts[index]["shared_by"] ?? []); 
    
    String message;
    
    if (sharedBy.contains(currentUsernameWithoutAt)) {
      sharedBy.remove(currentUsernameWithoutAt);
      message = "Membatalkan repost.";
    } else {
      sharedBy.add(currentUsernameWithoutAt);
      message = "Berhasil repost!";
      
      final postOwnerUsernameWithoutAt = _posts[index]["username"]!.substring(1);
      if (currentUsernameWithoutAt != postOwnerUsernameWithoutAt) {
          await NotificationStorage.addNotification({
              "type": "share", 
              "sender": _currentUser["username"]!,
              "message": "Membagikan postingan Anda.",
          }, postOwnerUsernameWithoutAt); // Recipient
      }
    }

    setState(() {
      _posts[index]["shared_by"] = sharedBy;
    });
    await PostStorage.savePosts(_posts);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // --- Widget Build Utama ---

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
          final isCurrentUserPost = post["username"] == _currentUser["username"];
          
          final currentUsername = _currentUser["username"]!.substring(1);
          final likedBy = List<String>.from(post["liked_by"] ?? []);
          final isLiked = likedBy.contains(currentUsername);
          final likeCount = likedBy.length;
          
          final sharedBy = List<String>.from(post["shared_by"] ?? []);
          final shareCount = sharedBy.length;
          
          final commentsList = List<Map<String, dynamic>>.from(post["comments_list"] ?? []);
          final commentCount = commentsList.length;

          final bool isCommentExpanded = _expandedCommentIndices.contains(index);
          final bool isFullComments = _fullCommentsIndices.contains(index);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(post["avatar"] ?? 'P', style: const TextStyle(color: Colors.deepPurple)),
                      ),
                      title: Row(
                        children: [
                          Text(post["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          
                          // PERBAIKAN OVERFLOW
                          Expanded(
                            child: Row(
                              children: [
                                Flexible( 
                                  child: Text(
                                    post["username"]!, 
                                    style: const TextStyle(color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                
                                const Spacer(),
                                
                                Text(
                                  "· ${_formatTimeAgo(post["timestamp"]!)}", 
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                      child: Text('Hapus Post', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                              icon: const Icon(Icons.more_vert),
                            )
                          : null,
                    ),
                    
                    // Menggunakan PostInteractionWidget
                    PostInteractionWidget(
                        post: post, 
                        currentUser: _currentUser,
                        index: index,
                        isCommentExpanded: isCommentExpanded,
                        isFullComments: isFullComments,
                        commentController: _commentController,
                        isPostOwner: isCurrentUserPost,
                        
                        // Passing Logic
                        onToggleLike: () => _toggleLike(index),
                        onToggleCommentSection: () => _toggleCommentSection(index),
                        onShare: () => _toggleShare(index),
                        onAddComment: () => _addComment(index), 
                        onToggleFullComments: () => _toggleFullComments(index),
                        onDeleteComment: _deleteComment,
                        
                        // Callback Reply Baru
                        onReply: (parentUsername, content) => _replyComment(index, parentUsername, content),

                        isLiked: isLiked, 
                        likeCount: likeCount, 
                        commentCount: commentCount, 
                        shareCount: shareCount, 
                        
                        commentsList: commentsList.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList(),
                        formatTimeAgo: _formatTimeAgo,
                    ),
                ],
              ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_currentUser["username"] == "@guest") {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Silahkan login untuk membuat postingan.")),
            );
            return;
          }

          final newPostData = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostPage(
                name: _currentUser["name"]!,
                username: _currentUser["username"]!,
              ),
            ),
          );

          if (newPostData != null) {
            final newPost = {
              "username": _currentUser["username"]!,
              "name": _currentUser["name"]!,
              "title": newPostData["title"] ?? "", // Menyimpan Judul
              "content": newPostData["content"]!, // Menyimpan Isi
              "timestamp": DateTime.now().toIso8601String(),
              "avatar": _currentUser["avatar"]!,
              "liked_by": [], 
              "comments_list": [], 
              "shared_by": [], 
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