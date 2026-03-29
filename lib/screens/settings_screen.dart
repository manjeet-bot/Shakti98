import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'admin_panel_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final token = await NotificationService.getFCMToken();
      setState(() {
        _fcmToken = token;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              AppBar(
                title: const Text('Settings'),
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildUserSection(),
                    const SizedBox(height: 24),
                    _buildNotificationSection(),
                    const SizedBox(height: 24),
                    _buildAppSection(),
                    const SizedBox(height: 24),
                    _buildAdminSection(),
                    const SizedBox(height: 24),
                    _buildLogoutSection(),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
                  ],
                ),
              ),
            ],
          ),
          // Watermark
          const Positioned(
            bottom: 20,
            right: 10,
            child: Opacity(
              opacity: 0.3,
              child: Text(
                'FIGHTING 58 SHAKTI 98',
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
    );
  }

  Widget _buildUserSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF4CAF50)),
              title: const Text('User ID', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                _authService.currentUserId,
                style: const TextStyle(color: Color(0xFF6C757D)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Color(0xFF4CAF50)),
              title: const Text('Authentication', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Anonymous User',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push Notifications', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Receive notifications for new messages',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _toggleNotifications(value);
              },
              activeThumbColor: const Color(0xFF4CAF50),
            ),
            if (_fcmToken != null)
              ListTile(
                leading: const Icon(Icons.token, color: Color(0xFF4CAF50)),
                title: const Text('FCM Token', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _fcmToken!,
                  style: const TextStyle(color: Color(0xFF6C757D), fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFF4CAF50)),
                  onPressed: () {
                    // Copy token to clipboard functionality would go here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FCM Token copied to clipboard'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.clear_all, color: Color(0xFF4CAF50)),
              title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Clear app cache and temporary data',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
              onTap: _clearCache,
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
              title: const Text('Reset Data', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Reset all app data (requires restart)',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
              onTap: _resetData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF4CAF50)),
              title: const Text('Version', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                '1.0.0',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF4CAF50)),
              title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
              onTap: _showPrivacyPolicy,
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Color(0xFF4CAF50)),
              title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
              onTap: _showHelp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool enabled) async {
    try {
      if (enabled) {
        await NotificationService.subscribeToTopic('all_users');
      } else {
        await NotificationService.unsubscribeFromTopic('all_users');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Notifications enabled' : 'Notifications disabled'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the app cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear cache logic would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _resetData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text(
          'This will reset all app data and sign you out. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to reset data: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Army Connect Pro Privacy Policy\n\n'
            'Data Collection:\n'
            'We collect only necessary data for app functionality including:\n'
            '- Anonymous user identification\n'
            '- Chat messages and images\n'
            '- Member information (admin only)\n\n'
            'Data Usage:\n'
            'Your data is used solely for:\n'
            '- Providing real-time messaging\n'
            '- Member management\n'
            '- App functionality\n\n'
            'Data Security:\n'
            'All data is encrypted and stored securely on Firebase servers.\n'
            'We do not share your data with third parties.\n\n'
            'Contact:\n'
            'For privacy concerns, contact the app administrator.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Text(
            'Army Connect Pro Help\n\n'
            'Getting Started:\n'
            '1. The app automatically signs you in anonymously\n'
            '2. Navigate between Chats, Members, and Settings\n\n'
            'Chat Features:\n'
            '- Create new chats using the + button\n'
            '- Send text and image messages\n'
            '- Real-time message synchronization\n'
            '- Typing indicators\n\n'
            'Member Management:\n'
            '- Access requires admin PIN (default: 1234)\n'
            '- Add, edit, and delete members\n'
            '- Search by service number\n'
            '- Filter by retirement date\n\n'
            'Troubleshooting:\n'
            '- Check internet connection for sync issues\n'
            '- Restart app if messages don\'t load\n'
            '- Clear cache if app is slow\n\n'
            'For technical support, contact the app administrator.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    return Card(
      color: const Color(0xFF1A1F2E),
      child: ListTile(
        leading: const Icon(
          Icons.admin_panel_settings,
          color: Color(0xFF9C27B0),
        ),
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            color: Color(0xFF9C27B0),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Manage members and system settings',
          style: TextStyle(color: Color(0xFF6C757D)),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPanelScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Card(
      color: const Color(0xFF1A1F2E),
      child: ListTile(
        leading: const Icon(
          Icons.logout,
          color: Color(0xFFD32F2F),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFD32F2F),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Sign out of your account',
          style: TextStyle(color: Color(0xFF6C757D)),
        ),
        onTap: _showLogoutDialog,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF6C757D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6C757D)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigation will be handled by AuthWrapper automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    }
  }
}
