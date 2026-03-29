import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/user_service.dart';
import '../widgets/app_logo.dart';
import 'package:flutter/services.dart';
import '../services/user_service.dart';
// Only import dart:io on non-web platforms
import 'dart:io' if (dart.library.html) 'dart:ui' as ui;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isGroupChat;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.isGroupChat,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      print('🔍 DEBUG: Sending message to chat ${widget.chatId}');
      print('🔍 DEBUG: Message text: ${_messageController.text.trim()}');
      print('🔍 DEBUG: Sender ID: ${user.uid}');
      
      // Add message to Firestore
      await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'text': _messageController.text.trim(),
        'senderId': user.uid,
        'senderEmail': user.email ?? 'Unknown',
        'senderName': user.displayName ?? user.email ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      print('🔍 DEBUG: Message added to subcollection');

      // Update chat last message - FIXED: Use updatedAt instead of lastMessageTime
      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': _messageController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageSender': user.email ?? 'Unknown',
      });

      print('🔍 DEBUG: Chat document updated with last message');
      print('🔍 DEBUG: Message sent successfully');

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('🔍 DEBUG: Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        print('📸 Starting image upload for chat...');
        
        // Simple base64 approach - no Firebase Storage
        try {
          final Uint8List imageBytes = await image.readAsBytes();
          print('✅ Image bytes read: ${imageBytes.length}');
          
          // Convert to base64
          final base64String = base64Encode(imageBytes);
          final dataUrl = 'data:image/jpeg;base64,$base64String';
          print('✅ Image converted to base64, length: ${base64String.length}');

          // Create message with base64 data URL
          await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
            'type': 'image',
            'imageUrl': dataUrl,
            'senderId': user.uid,
            'senderEmail': user.email ?? 'Unknown',
            'senderName': user.displayName ?? user.email ?? 'Unknown',
            'timestamp': FieldValue.serverTimestamp(),
          });

          print('✅ Image message sent successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image sent!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        } catch (uploadError) {
          print('❌ Error uploading image: $uploadError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send image: $uploadError'),
              backgroundColor: const Color(0xFFDC143C),
            ),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error in _sendImage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC143C),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Show delete chat confirmation dialog
  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteChat();
              },
              child: const Text('Delete', style: TextStyle(color: Color(0xFFDC143C))),
            ),
          ],
        );
      },
    );
  }

  // Delete chat function
  Future<void> _deleteChat() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete all messages in the chat
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .get();

        for (final doc in messagesSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete the chat document
        await _firestore.collection('chats').doc(widget.chatId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        // Navigate back to chat list
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat: $e'),
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
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                title: Text(widget.chatName),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (String value) {
                      if (value == 'delete_chat') {
                        _showDeleteChatDialog();
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem<String>(
                          value: 'delete_chat',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Color(0xFFDC143C), size: 20),
                              const SizedBox(width: 8),
                              const Text('Delete Chat', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              // Messages List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFDC143C)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Color(0xFFDC143C)),
                        ),
                      );
                    }

                    final messages = snapshot.data?.docs ?? [];

                    if (messages.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppLogo(size: 64),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final messageData = message.data() as Map<String, dynamic>;
                        final isMe = messageData['senderId'] == _auth.currentUser?.uid;
                        final senderName = messageData['senderName'] ?? 'Unknown';
                        final messageType = messageData['type'] ?? 'text';
                        final messageText = messageData['text'] ?? '';
                        final imageUrl = messageData['imageUrl'];
                        final timestamp = messageData['timestamp'] as Timestamp?;

                        return _MessageBubble(
                          text: messageText,
                          isMe: isMe,
                          senderName: senderName,
                          timestamp: timestamp,
                          type: messageType,
                          imageUrl: imageUrl,
                          senderId: messageData['senderId'],
                        );
                      },
                    );
                  },
                ),
              ),
              // Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  border: Border(
                    top: BorderSide(color: Color(0xFFDC143C)),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _sendImage,
                      icon: const Icon(
                        Icons.image,
                        color: Color(0xFFDC143C),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(color: Color(0xFF888888)),
                          filled: true,
                          fillColor: const Color(0xFF0A0A0A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC143C)),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Color(0xFFDC143C),
                            ),
                    ),
                  ],
                ),
              ),
            ],
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String senderName;
  final Timestamp? timestamp;
  final String? type;
  final String? imageUrl;
  final String? senderId;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.senderName,
    this.timestamp,
    this.type,
    this.imageUrl,
    this.senderId,
  });

  @override
  Widget build(BuildContext context) {
    final time = timestamp != null ? _formatTime(timestamp!.toDate()) : '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Row(
              children: [
                _buildUserProfilePhoto(senderId),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) const SizedBox(width: 40),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: type == 'image' 
                      ? const EdgeInsets.all(8)
                      : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF8B0000) : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFDC143C).withOpacity(0.3),
                    ),
                  ),
                  child: type == 'image' 
                      ? _buildImageMessage()
                      : Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              if (isMe) const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfilePhoto(String? userId) {
    if (userId == null) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFFDC143C),
        child: Icon(
          Icons.person,
          size: 16,
          color: Colors.white,
        ),
      );
    }

    return FutureBuilder<String?>(
      future: UserService.getUserProfileImage(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFDC143C),
            child: SizedBox(
              width: 16,
              height: 16,
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
              radius: 16,
              backgroundColor: const Color(0xFFDC143C),
              backgroundImage: MemoryImage(base64Decode(profileImageUrl.split(',')[1])) as ImageProvider,
            );
          } else if (profileImageUrl.startsWith('http')) {
            return CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFDC143C),
              backgroundImage: NetworkImage(profileImageUrl),
            );
          }
        }

        // Default avatar
        return CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFDC143C),
          child: const Icon(
            Icons.person,
            size: 16,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildImageMessage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      Widget imageWidget;
      
      // Check if it's a base64 image
      if (imageUrl!.startsWith('data:image')) {
        imageWidget = Image.memory(
          base64Decode(imageUrl!.split(',')[1]),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        );
      } else {
        // Network image
        imageWidget = Image.network(
          imageUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1B5E20),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      );
    } else {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text('Image not available', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.minute}:${dateTime.second.toString().padLeft(2, '0')}';
    }
  }
}
