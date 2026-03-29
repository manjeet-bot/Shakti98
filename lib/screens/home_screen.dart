import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/chat_list_screen.dart';
import '../screens/user_list_screen.dart';
import '../screens/personal_details_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/member_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Widget> get _screens {
    final isAdmin = _auth.currentUser?.email == 'admin@army.com';
    
    List<Widget> screens = [
      const ChatListScreen(),
      const UserListScreen(),
      const PersonalDetailsScreen(),
      const SettingsScreen(),
    ];
    
    // Only add Member tab for admin
    if (isAdmin) {
      screens.insert(2, const MemberListScreen());
    }
    
    return screens;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Watermark
          const Positioned(
            bottom: 80,
            right: 10,
            child: Opacity(
              opacity: 0.3,
              child: Text(
                'SHAKTI PARIWAR',
                style: TextStyle(
                  color: Color(0xFFDC143C),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: _buildBottomNavItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    final isAdmin = _auth.currentUser?.email == 'admin@army.com';
    
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat),
        label: 'Chats',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_search),
        label: 'Users',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
    
    // Add Members tab only for admin
    if (isAdmin) {
      items.insert(2, const BottomNavigationBarItem(
        icon: Icon(Icons.group),
        label: 'Members',
      ));
    }
    
    return items;
  }
}
