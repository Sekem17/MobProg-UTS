import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PostStorage {
  static Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'posts.json');
    return path;
  }

  static Future<void> savePosts(List<Map<String, dynamic>> posts) async {
    final file = File(await getFilePath());
    final jsonString = jsonEncode(posts);
    await file.writeAsString(jsonString);
  }

  static Future<List<Map<String, dynamic>>> loadPosts() async {
    try {
      final file = File(await getFilePath());
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error loading posts: $e');
      return [];
    }
  }

  static Future<void> deletePosts() async {}
}