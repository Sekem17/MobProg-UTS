import 'package:flutter/material.dart';
import 'pages/main_screen.dart'; 
import 'pages/login_page.dart ';
import 'pages/register_page.dart';
import 'pages/home_screen.dart';
import 'pages/post_screen.dart';
import 'pages/dm_screen.dart';
import 'pages/explore_screen.dart';
import 'pages/notif_screen.dart';

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
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}