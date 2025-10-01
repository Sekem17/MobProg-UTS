import 'package:flutter/material.dart';
import 'package:medsos/storage/chat_storage.dart'; 
import 'package:intl/intl.dart'; 

class ChatRoomPage extends StatefulWidget {
  final String otherUser; // Username user yang dichat (tanpa @)
  final String currentUser; // Username user yang login (tanpa @)
  final String name; // Nama user yang dichat
  final String username; // Username user yang dichat (dengan @)

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
  
  // Pesan sekarang menggunakan Map<String, dynamic> karena is_deleted adalah String/Bool
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }
  
  Future<void> _loadMessages() async {
    // Perhatikan cast ke List<Map<String, dynamic>>
    final loadedMessages = (await ChatStorage.loadMessages(
        widget.currentUser, widget.otherUser)).map((e) => e as Map<String, dynamic>).toList();
    
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

  // --- Fitur Hapus Pesan & Riwayat ---

  // Menandai pesan sebagai terhapus dan menyimpan ke storage
  void _deleteMessage(int index) async {
    setState(() {
      // Tandai pesan sebagai terhapus
      _messages[index]["is_deleted"] = "true";
      // Opsional: hapus content agar lebih bersih di storage, tapi tetap simpan timestamp/sender
      // _messages[index]["content"] = "(Pesan telah dihapus)"; 
    });
    
    // Simpan list pesan yang sudah diperbarui
    // Gunakan Map<String, String> di sini agar sesuai dengan signature ChatStorage.saveMessages
    await ChatStorage.saveMessages(
      widget.currentUser, 
      widget.otherUser, 
      _messages.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList()
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pesan berhasil dihapus.")),
    );
  }

  // Hapus seluruh riwayat chat (Clear History)
  void _clearChatHistory() async {
    // Kosongkan list pesan secara lokal
    setState(() {
      _messages = [];
    });
    
    // Simpan list kosong ke storage
    await ChatStorage.saveMessages(widget.currentUser, widget.otherUser, []);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Riwayat chat berhasil dihapus!")),
    );
  }
  
  // Menampilkan menu hapus saat pesan ditekan lama
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
                  Navigator.pop(bc); // Tutup bottom sheet
                  _deleteMessage(index); // Panggil fungsi hapus
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

  // --- Kirim Pesan ---

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final newMessage = {
      "sender": widget.currentUser, 
      "content": text,
      "timestamp": DateTime.now().toIso8601String(), // Simpan timestamp
      "is_deleted": "false", // Status default pesan
    };

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();
    
    // Simpan pesan baru. Perhatikan konversi ke Map<String, String>
    await ChatStorage.saveMessages(
      widget.currentUser, 
      widget.otherUser, 
      _messages.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList()
    );

    if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
    }
  }
  
  // --- Tampilan Pesan & Timestamp ---

  // Helper untuk format waktu
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(dateTime); // Format jam:menit
    } catch (e) {
      return '';
    }
  }


  // Widget untuk menampilkan gelembung pesan
  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isMe = message["sender"] == widget.currentUser; 
    final time = _formatTimestamp(message["timestamp"]); 
    final isDeleted = message["is_deleted"] == "true"; 
    
    // Konten yang ditampilkan di dalam gelembung
    final String content = isDeleted 
        ? "(message was deleted)" 
        : (message["content"] as String? ?? "Pesan kosong"); // Fallback jika content null
        
    // Warna gelembung
    final bubbleColor = isDeleted 
        ? Colors.grey.shade400 
        : (isMe ? Colors.deepPurple.shade300 : Colors.grey.shade300);

    // Warna teks
    final textColor = isDeleted 
        ? Colors.black54 
        : (isMe ? Colors.white : Colors.black87);
        
    // Style teks
    final contentStyle = TextStyle(
        color: textColor, 
        fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal
    );
    
    // Pesan hanya bisa dihapus jika itu pesan kita DAN belum dihapus
    final canDelete = isMe && !isDeleted;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // Tambahkan logic pop-up menu saat ditekan lama
        onLongPress: () {
          if (canDelete) {
            _showDeleteMenu(context, index);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Gelembung Pesan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                    bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                  ),
                ),
                child: Text(
                  content,
                  style: contentStyle,
                ),
              ),
              
              // Timestamp di bawah gelembung
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4, right: 4, left: 4),
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

  // --- Widget Build Utama ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.username, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          // Tombol Hapus Riwayat Chat
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      // Lewatkan index agar pesan bisa dihapus
                      return _buildMessageBubble(message, index); 
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, offset: const Offset(0, -2), blurRadius: 4),
              ]
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