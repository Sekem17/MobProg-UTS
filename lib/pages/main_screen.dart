import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'notif_screen.dart';
import 'dm_screen.dart';
import 'package:medsos/pages/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _currentUsername = '@guest';
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); 
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('current_user'); 

    setState(() {
      _currentUsername = '@${currentUsername ?? 'guest'}';
      _isInitialLoad = false;
    });
  }

  void _onItemTapped(int index) async {
    await _loadCurrentUser();

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_currentUsername == '@guest') {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final universalKey = 'user_reload_${_currentUsername}_$_selectedIndex';

    final List<Widget> pages = [
      HomePage(key: ValueKey(universalKey)),
      SearchPage(key: ValueKey(universalKey)),
      NotificationPage(key: ValueKey(universalKey)),
      DmPage(key: ValueKey(universalKey)),
      ProfilePage(
        key: ValueKey(universalKey), 
        targetUsername: _currentUsername,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 0, 157, 255),
        unselectedItemColor: const Color.fromARGB(255, 115, 115, 115),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}