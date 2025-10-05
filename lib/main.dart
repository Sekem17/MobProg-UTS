import 'package:flutter/material.dart';
import 'package:medsos/pages/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:medsos/models/theme.dart';
import 'pages/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeManager>(
      create: (_) => ThemeManager(),

      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'YAPP - UTS Mobile Programming',
            debugShowCheckedModeBanner: false,

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: themeManager.themeMode,

            home: const WelcomePage(),
            routes: {'/main': (context) => const MainScreen()},
          );
        },
      ),
    );
  }
}
