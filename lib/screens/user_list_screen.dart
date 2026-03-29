import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../screens/chat_screen.dart';
import '../models/chat_model.dart';
import '../widgets/app_logo.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _users = [];
  bool _isLoading = true;
  StreamSubscription? _usersSubscription; // FIXED: Add stream subscription

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() { 
    _usersSubscription?.cancel();
    super.dispose();
  }

  void _loadUsers() async {
    _usersSubscription = _firestore
        .collection('users')
        .where('uid', isNotEqualTo: _auth.currentUser?.uid)
        .snapshots()
        .listen((snapshot) {
      if (mounted) { // FIXED: Check if widget is still mounted
        setState(() {
          _users = snapshot.docs;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _createChatWithUser(String targetUserId, String targetUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      print('🔍 DEBUG: Creating chat between ${currentUser.uid} and $targetUserId');
      
      // FIXED: Create unique chatId by sorting both user IDs
      final List<String> userIds = [currentUser.uid, targetUserId];
      userIds.sort(); // Sort to ensure consistent ordering
      final chatId = userIds.join('_'); // e.g., "uid1_uid2"
      
      print('🔍 DEBUG: Generated chatId: $chatId');

      // FIXED: Use direct document access instead of query
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      print('🔍 DEBUG: Chat document exists: ${chatDoc.exists}');

      if (chatDoc.exists) {
        print('🔍 DEBUG: Chat already exists, navigating to existing chat');
        // Chat already exists, navigate to it
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              chatName: targetUserName,
              isGroupChat: false,
            ),
          ),
        );
      } else {
        print('🔍 DEBUG: Creating new chat document');
        // FIXED: Create new chat with proper structure
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [currentUser.uid, targetUserId],
          'lastMessage': '',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageSender': '',
          'isGroupChat': false,
          'chatName': targetUserName,
        });
        
        print('🔍 DEBUG: New chat created successfully');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              chatName: targetUserName,
              isGroupChat: false,
            ),
          ),
        );
      }
    } catch (e) {
      print('🔍 DEBUG: Error creating chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create chat: $e'),
          backgroundColor: const Color(0xFFDC143C),
        ),
      );
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
                title: const Text('Users'),
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFDC143C)),
                      )
                    : _users.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppLogo(size: 64),
                                SizedBox(height: 16),
                                Text(
                                  'No other users found',
                                  style: TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ask your friends to register!',
                                  style: TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final userData = user.data() as Map<String, dynamic>;
                              final userName = userData['displayName'] ?? userData['email'] ?? 'Unknown';
                              final userEmail = userData['email'] ?? 'No email';
                              final isOnline = userData['isOnline'] ?? false;

                              return ListTile(
                                leading: _buildUserProfilePhoto(user.id, isOnline),
                                title: Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  userEmail,
                                  style: const TextStyle(
                                    color: Color(0xFF888888),
                                  ),
                                ),
                                trailing: isOnline
                                    ? Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFDC143C),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () => _createChatWithUser(user.id, userName),
                                tileColor: const Color(0xFF1A1A2E),
                              );
                            },
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
    );
  }

  Widget _buildUserProfilePhoto(String userId, bool isOnline) {
    return FutureBuilder<String?>(
      future: UserService.getUserProfileImage(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 20,
            backgroundColor: isOnline ? const Color(0xFFDC143C) : const Color(0xFF888888),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        final profileImageUrl = snapshot.data;
        if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
          // Check if it's a base64 image
          if (profileImageUrl.startsWith('data:image')) {
            return CircleAvatar(
              radius: 20,
              backgroundColor: isOnline ? const Color(0xFFDC143C) : const Color(0xFF888888),
              backgroundImage: MemoryImage(base64Decode(profileImageUrl.split(',')[1])) as ImageProvider,
            );
          } else if (profileImageUrl.startsWith('http')) {
            return CircleAvatar(
              radius: 20,
              backgroundColor: isOnline ? const Color(0xFFDC143C) : const Color(0xFF888888),
              backgroundImage: NetworkImage(profileImageUrl),
            );
          }
        }

        // Default avatar with initial
        return FutureBuilder<String>(
          future: UserService.getUserName(userId),
          builder: (context, nameSnapshot) {
            final userName = nameSnapshot.data ?? 'Unknown';
            return CircleAvatar(
              radius: 20,
              backgroundColor: isOnline ? const Color(0xFFDC143C) : const Color(0xFF888888),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
