import 'package:flutter/material.dart';
import 'package:medsos/storage/chat_storage.dart';
import 'package:intl/intl.dart';

class ChatRoomPage extends StatefulWidget {
  final String otherUser;
  final String currentUser;
  final String name;
  final String username;

  const ChatRoomPage({
    required this.otherUser,
    required this.currentUser,
    required this.name,
    required this.username,
    super.key,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final loadedMessages = (await ChatStorage.loadMessages(
      widget.currentUser,
      widget.otherUser,
    )).map((e) => e as Map<String, dynamic>).toList();

    setState(() {
      _messages = loadedMessages;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _deleteMessage(int index) async {
    setState(() {
      _messages[index]["is_deleted"] = "true";
    });

    await ChatStorage.saveMessages(
      widget.currentUser,
      widget.otherUser,
      _messages.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList(),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Pesan berhasil dihapus.")));
  }

  void _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat?'),
        content: const Text(
          'Anda yakin ingin menghapus seluruh riwayat percakapan ini? Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _messages = [];
      });

      await ChatStorage.saveMessages(widget.currentUser, widget.otherUser, []);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Riwayat chat berhasil dihapus!")),
      );
    }
  }

  void _showDeleteMenu(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Hapus Pesan Ini'),
                onTap: () {
                  Navigator.pop(bc);
                  _deleteMessage(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = {
      "sender": widget.currentUser,
      "content": text,
      "timestamp": DateTime.now().toIso8601String(),
      "is_deleted": "false",
    };

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();

    await ChatStorage.saveMessages(
      widget.currentUser,
      widget.otherUser,
      _messages.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList(),
    );

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isMe = message["sender"] == widget.currentUser;
    final time = _formatTimestamp(message["timestamp"]);
    final isDeleted = message["is_deleted"] == "true";

    final String content = isDeleted
        ? "(message was deleted)"
        : (message["content"] as String? ?? "Pesan kosong");

    final bubbleColor = isDeleted
        ? Colors.grey.shade500
        : (isMe ? Colors.deepPurple : Colors.white);

    final textColor = isDeleted
        ? Colors.black45
        : (isMe ? Colors.white : Colors.black87);

    final contentStyle = TextStyle(
      color: textColor,
      fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
    );

    final canDelete = isMe && !isDeleted;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          if (canDelete) {
            _showDeleteMenu(context, index);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isMe
                        ? const Radius.circular(12)
                        : const Radius.circular(0),
                    bottomRight: isMe
                        ? const Radius.circular(0)
                        : const Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Text(content, style: contentStyle),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 4,
                  bottom: 4,
                  right: 4,
                  left: 4,
                ),
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.username,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChatHistory,
            tooltip: "Hapus Riwayat Chat",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/gambar/bgdm.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message, index);
                      },
                    ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Ketik pesan...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.deepPurple),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
