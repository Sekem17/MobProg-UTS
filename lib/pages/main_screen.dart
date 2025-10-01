import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Wajib diimport
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
  List<Widget> _pages = [const CircularProgressIndicator()]; // Default loading state
  String _currentUsername = '@guest'; // Default username

  @override
  void initState() {
    super.initState();
    _initializePages();
  }
  
  // FUNGSI BARU: Memuat user dan menyusun list halaman
  Future<void> _initializePages() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('current_user');
    
    // Simpan username untuk digunakan di ProfilPage
    _currentUsername = '@${currentUsername ?? 'guest'}';
    
    // Susun list halaman setelah username dimuat
    setState(() {
      _pages = [
        const HomePage(),          
        const SearchPage(),        
        const NotificationPage(),  
        const DmPage(),
        // Memberikan username saat ini ke ProfilPage
        ProfilePage(targetUsername: _currentUsername), 
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan CircularProgressIndicator jika _pages belum selesai dimuat
    if (_pages.length == 1 && _selectedIndex == 0 && _pages[0] is CircularProgressIndicator) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      body: _pages[_selectedIndex], 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Messages"), 
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"), 
        ],
      ),
    );
  }
}