import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  final List<Map<String, String>> accounts = [
    {"name": "John Doe", "username": "@johndoe", "avatar": "JD"},
    {"name": "Jose Alexander", "username": "@josealex", "avatar": "JA"},
    {"name": "Flutter Dev", "username": "@flutterdev", "avatar": "FD"},
    {"name": "Coding Life", "username": "@codelife", "avatar": "CL"},
    {"name": "Nasi Goreng Lovers", "username": "@nasigoreng", "avatar": "NG"},
    {"name": "OpenAI Bot", "username": "@gptbot", "avatar": "GB"},
    {"name": "Anime Fans", "username": "@otaku", "avatar": "OF"},
  ];

  String query = "";

  @override
  Widget build(BuildContext context) {
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