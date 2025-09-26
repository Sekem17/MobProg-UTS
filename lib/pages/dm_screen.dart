// dm_screen.dart
import 'package:flutter/material.dart';

class DmPage extends StatelessWidget {
  const DmPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy untuk daftar percakapan DM
    final List<Map<String, String>> dms = [
      {
        "username": "@skm",
        "name": "Sekem",
        "last_message": "Ada di mana, bro?",
        "time": "15m",
        "avatar": "assets/gambar/avatarpp.jpg",
      },
      {
        "username": "@mahmud",
        "name": "Mahmud",
        "last_message": "Tugasnya udah dikerjain?",
        "time": "1j",
        "avatar": "assets/gambar/ppbebek.jpg",
      },
      {
        "username": "@hammy",
        "name": "xiao ham",
        "last_message": "Jangan lupa rapat besok ya.",
        "time": "4j",
        "avatar": "assets/gambar/hampp.jpg",
      },
      {
        "username": "@joko",
        "name": "Joko",
        "last_message": "Oke, siap!",
        "time": "1h",
        "avatar": "assets/gambar/avatarpp.jpg",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Direct Messages'), centerTitle: true),
      body: ListView.builder(
        itemCount: dms.length,
        itemBuilder: (context, index) {
          final dm = dms[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(backgroundImage: AssetImage(dm["avatar"]!)),
              title: Row(
                children: [
                  Text(
                    dm["name"]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dm["username"]!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    dm["time"]!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  dm["last_message"]!,
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Membuka percakapan dengan ${dm["name"]}"),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
