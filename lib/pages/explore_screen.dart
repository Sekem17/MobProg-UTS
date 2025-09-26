import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Dummy data akun
  final List<Map<String, String>> accounts = [
    {"name": "Jose Alexander", "username": "@josealex", "avatar": "👨"},
    {"name": "Flutter Dev", "username": "@flutterdev", "avatar": "💙"},
    {"name": "Coding Life", "username": "@codelife", "avatar": "💻"},
    {"name": "Nasi Goreng Lovers", "username": "@nasigoreng", "avatar": "🍚"},
    {"name": "OpenAI Bot", "username": "@gptbot", "avatar": "🤖"},
    {"name": "Anime Fans", "username": "@otaku", "avatar": "🎌"},
  ];

  String query = "";

  @override
  Widget build(BuildContext context) {
    // Filter akun sesuai nama atau username
    final filteredAccounts = accounts.where((account) {
      final name = account["name"]!.toLowerCase();
      final username = account["username"]!.toLowerCase();
      final input = query.toLowerCase();
      return name.contains(input) || username.contains(input);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Explore"), centerTitle: true),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari akun...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),

          // List hasil pencarian akun
          Expanded(
            child: filteredAccounts.isEmpty
                ? const Center(child: Text("Akun tidak ditemukan"))
                : ListView.builder(
                    itemCount: filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = filteredAccounts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          child: Text(account["avatar"]!),
                        ),
                        title: Text(account["name"]!),
                        subtitle: Text(account["username"]!),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text("Follow"),
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
