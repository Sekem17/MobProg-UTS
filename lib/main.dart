import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xwritter - UTS Mobile Programming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Xwritter'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> posts = [
      {
        "username": "@skm",
        "name": "Sekem",
        "content": "Halo semua btw p, bl bang",
        "time": "2m",
        "avatar": "assets/gambar/avatarpp.jpg"
      },
      {
        "username": "@mahmud",
        "name": "Mahmud",
        "content": "Flutter go flutter 🚀",
        "time": "10m",
        "avatar": "assets/gambar/ppbebek.jpg"
      },
      {
        "username": "@hammy",
        "name": "xiao ham",
        "content": "Ayo join UNTAR 🔥",
        "time": "30m",
        "avatar": "assets/gambar/hampp.jpg"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(post["avatar"]!), 
              ),
              title: Row(
                children: [
                  Text(
                    post["name"]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    post["username"]!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "· ${post["time"]}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(post["content"]!),
              ),
              trailing: const Icon(Icons.more_vert),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tombol posting ditekan")),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Notifikasi"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
