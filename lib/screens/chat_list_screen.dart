import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../screens/chat_screen.dart';
import '../screens/user_profile_view_screen.dart';
import '../models/chat_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<Chat>> _chatsStream;
  Map<String, String> _userNames = {};
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isSearching = false;
  bool _showUserSearch = false;

  @override
  void initState() {
    super.initState();
    _chatsStream = _chatService.getUserChats(_authService.currentUserId);
    _loadUserNames();
    _loadAllUsers();
    _debugCurrentUser();
  }

  void _debugCurrentUser() {
    final user = _auth.currentUser;
    print('🔍 DEBUG: Current User ID: ${user?.uid}');
    print('🔍 DEBUG: Current User Email: ${user?.email}');
    print('🔍 DEBUG: Is Authenticated: ${user != null}');
  }

  Future<void> _loadUserNames() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _userNames[doc.id] = data['displayName'] ?? data['name'] ?? data['email'] ?? 'Unknown';
      }
      if (mounted) { // FIXED: Check if widget is still mounted
        setState(() {});
      }
    } catch (e) {
      print('Error loading user names: $e');
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final currentUserId = _auth.currentUser?.uid;
      
      _allUsers = usersSnapshot.docs
          .where((doc) => doc.id != currentUserId) // Exclude current user
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'uid': doc.id,
              'displayName': data['displayName'] ?? data['name'] ?? data['email'] ?? 'Unknown',
              'email': data['email'] ?? 'No email',
              'rank': data['rank'] ?? 'Not specified',
              'coy': data['coy'] ?? 'Not specified',
              'bloodGroup': data['bloodGroup'] ?? 'Not specified',
              'posting': data['posting'] ?? 'Not specified',
              'unit': data['unit'] ?? 'Not specified',
              'phone': data['phone'] ?? 'Not specified',
              'address': data['address'] ?? 'Not specified',
              'emergencyContact': data['emergencyContact'] ?? 'Not specified',
              'role': data['role'] ?? 'Not specified',
              'profileImageUrl': data['profileImageUrl'] ?? '',
              'createdAt': data['createdAt'] ?? DateTime.now(),
            };
          })
          .toList();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading all users: $e');
    }
  }

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredUsers = _allUsers.where((user) {
        final name = user['displayName'].toString().toLowerCase();
        final email = user['email'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    });
  }

  void _viewUserProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(userData: user),
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl, String displayName, {double size = 40}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // Default avatar with first letter
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF4CAF50),
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Check if it's a data URL (base64)
    if (imageUrl.startsWith('data:image')) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF4CAF50),
        backgroundImage: MemoryImage(base64Decode(imageUrl.split(',')[1])),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to default avatar
        },
        child: imageUrl.isEmpty ? Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ) : null,
      );
    }

    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF4CAF50),
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to default avatar
        },
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Default fallback
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF4CAF50),
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getChatDisplayName(Chat chat) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return chat.name;
    
    // Find the other user in participants
    for (String participantId in chat.participants) {
      if (participantId != currentUserId) {
        return _userNames[participantId] ?? 'Unknown User';
      }
    }
    
    return chat.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showUserSearch 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search users by name or email...',
                  hintStyle: TextStyle(color: Color(0xFFB0BEC5)),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _searchUsers,
              )
            : const Text('58 Engr Regt'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showUserSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showUserSearch = !_showUserSearch;
                if (!_showUserSearch) {
                  _searchController.clear();
                  _filteredUsers.clear();
                  _isSearching = false;
                }
              });
            },
          ),
        ],
      ),
      body: _showUserSearch ? _buildUserSearchResults() : _buildChatList(),
    );
  }

  Widget _buildUserSearchResults() {
    if (!_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Color(0xFF6C757D)),
            SizedBox(height: 16),
            Text(
              'Search for users by name or email',
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Color(0xFF6C757D)),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserSearchItem(user);
      },
    );
  }

  Widget _buildUserSearchItem(Map<String, dynamic> user) {
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildProfileImage(
          user['profileImageUrl'] ?? '',
          user['displayName'],
          size: 50,
        ),
        title: Text(
          user['displayName'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          user['email'],
          style: const TextStyle(
            color: Color(0xFF6C757D),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF6C757D), size: 16),
        onTap: () => _viewUserProfile(user),
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<Chat>>(
      stream: _chatsStream,
      builder: (context, snapshot) {
        print('🔍 DEBUG: Chat Stream State: ${snapshot.connectionState}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }

        if (snapshot.hasError) {
          print('🔍 DEBUG: Chat Stream Error: ${snapshot.error}');
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFFDC143C)),
            ),
          );
        }

        final chats = snapshot.data ?? [];
        print('🔍 DEBUG: Number of chats found: ${chats.length}');

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Color(0xFF6C757D),
                ),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(
                    color: const Color(0xFF6C757D),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _createNewChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Your First Chat'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            print('🔍 DEBUG: Chat ${index + 1}: ${chat.id}, Participants: ${chat.participants}');
            return _buildChatItem(chat);
          },
        );
      },
    );
  }

  Widget _buildChatItem(Chat chat) {
    final displayName = _getChatDisplayName(chat);
    final currentUserId = _auth.currentUser?.uid;
    
    // Find the other user's ID to get their profile image
    String? otherUserId;
    for (String participantId in chat.participants) {
      if (participantId != currentUserId) {
        otherUserId = participantId;
        break;
      }
    }
    
    // Get user data for profile image
    Map<String, dynamic>? otherUserData;
    if (otherUserId != null) {
      otherUserData = _allUsers.firstWhere(
        (user) => user['uid'] == otherUserId,
        orElse: () => {'profileImageUrl': '', 'displayName': displayName},
      );
    }
    
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildProfileImage(
          otherUserData?['profileImageUrl'] ?? '',
          displayName,
          size: 50,
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          chat.lastMessage?.isNotEmpty == true 
              ? chat.lastMessage! 
              : 'No messages yet',
          style: const TextStyle(
            color: Color(0xFF6C757D),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: chat.updatedAt != null
            ? Text(
                _formatTimestamp(chat.updatedAt!),
                style: const TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 12,
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chat.id,
                chatName: displayName,
                isGroupChat: false,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _createNewChat() async {
    // DEBUG: Create a test chat to verify functionality
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('🔍 DEBUG: No current user found');
      return;
    }

    print('🔍 DEBUG: Creating test chat for user: ${currentUser.uid}');
    
    // Navigate to Users tab to create a chat
    DefaultTabController.of(context)?.animateTo(1); // Switch to Users tab
    showDialog(
      context: context,
      builder: (context) => _CreateChatDialog(
        onChatCreated: (chatName, participants) async {
          try {
            final chatId = await _chatService.createChat(chatName, participants);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat created successfully'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create chat: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

class _CreateChatDialog extends StatefulWidget {
  final Function(String chatName, List<String> participants) onChatCreated;

  const _CreateChatDialog({required this.onChatCreated});

  @override
  State<_CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends State<_CreateChatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Chat'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Chat Name',
                hintText: 'Enter chat name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a chat name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createChat,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createChat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      
      widget.onChatCreated(
        _nameController.text.trim(),
        [authService.currentUserId],
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
