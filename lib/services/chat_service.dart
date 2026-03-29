import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:uuid/uuid.dart';

import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart';

import 'dart:io';

import 'dart:convert';

import '../models/chat_model.dart';



class Message {

  final String id;

  final String senderId;

  final String text;

  final String? imageUrl;

  final Timestamp timestamp;

  final bool isTyping;



  Message({

    required this.id,

    required this.senderId,

    required this.text,

    this.imageUrl,

    required this.timestamp,

    this.isTyping = false,

  });



  factory Message.fromFirestore(DocumentSnapshot doc) {

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Message(

      id: doc.id,

      senderId: data['senderId'] ?? '',

      text: data['text'] ?? '',

      imageUrl: data['imageUrl'],

      timestamp: data['timestamp'] ?? Timestamp.now(),

      isTyping: data['isTyping'] ?? false,

    );

  }



  Map<String, dynamic> toFirestore() {

    return {

      'senderId': senderId,

      'text': text,

      'imageUrl': imageUrl,

      'timestamp': timestamp,

      'isTyping': isTyping,

    };

  }

}



class ChatService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  final ImagePicker _imagePicker = ImagePicker();



  // Get all chats for current user - FIXED: Simplified query to avoid index requirement
  Stream<List<Chat>> getUserChats(String userId) {
    print('🔍 DEBUG: Querying chats for user: $userId');
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId) // Single filter only
        .snapshots()
        .map((snapshot) {
          print('🔍 DEBUG: Firestore snapshot received: ${snapshot.docs.length} documents');
          final chats = snapshot.docs
              .map((doc) {
                final chat = Chat.fromFirestore(doc);
                print('🔍 DEBUG: Chat found: ${chat.id}, Participants: ${chat.participants}');
                return chat;
              })
              .toList();
          
          // Sort client-side by updatedAt to avoid index requirement
          chats.sort((a, b) {
            if (a.updatedAt == null && b.updatedAt == null) return 0;
            if (a.updatedAt == null) return 1;
            if (b.updatedAt == null) return -1;
            return b.updatedAt!.compareTo(a.updatedAt!);
          });
          
          print('🔍 DEBUG: Total chats processed: ${chats.length}');
          return chats;
        })
        .handleError((error) {
          print('❌ Firebase Permission Error in getUserChats: $error');
          if (error.toString().contains('permission-denied')) {
            print('🔧 SOLUTION: Deploy Firebase security rules from firestore.rules file');
            print('🔧 See FIREBASE_PERMISSION_FIX.md for instructions');
          }
          throw Exception('Chat access denied. Please check Firebase security rules.');
        });
  }



  // Get messages for a specific chat - FIXED: Direct query without Message class
  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
            .toList())
        .handleError((error) {
          print('❌ Firebase Permission Error in getChatMessages: $error');
          if (error.toString().contains('permission-denied')) {
            print('🔧 SOLUTION: Deploy Firebase security rules from firestore.rules file');
            print('🔧 See FIREBASE_PERMISSION_FIX.md for instructions');
          }
          throw Exception('Message access denied. Please check Firebase security rules.');
        });
  }



  // Send text message - FIXED: Uses proper message structure
  Future<void> sendTextMessage(String chatId, String senderId, String text) async {
    final messageId = const Uuid().v4();
    
    // FIXED: Create message with proper structure
    final messageData = {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    };

    try {
      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // FIXED: Update chat's last message and updatedAt
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
      });
    } catch (e) {
      print('❌ Firebase Permission Error in sendTextMessage: $e');
      if (e.toString().contains('permission-denied')) {
        print('🔧 SOLUTION: Deploy Firebase security rules from firestore.rules file');
        print('🔧 See FIREBASE_PERMISSION_FIX.md for instructions');
      }
      throw Exception('Failed to send message. Please check Firebase security rules.');
    }
  }



  // Upload image to Firebase Storage (completely simplified - base64 only)
  Future<String?> uploadImage(dynamic imageFile, String chatId) async {
    try {
      print('📸 Starting image upload for chat: $chatId');
      
      // Handle different image types
      if (imageFile is XFile) {
        // For XFile (from image picker)
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        print('✅ Image converted to base64, length: ${base64String.length}');
        return dataUrl;
      } else if (imageFile is File) {
        // For File (mobile)
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        print('✅ File converted to base64, length: ${base64String.length}');
        return dataUrl;
      } else if (imageFile is String && imageFile.startsWith('data:image')) {
        // Already a data URL
        print('✅ Already a data URL');
        return imageFile;
      } else if (imageFile is String && imageFile.startsWith('http')) {
        // Network URL
        print('✅ Network URL: $imageFile');
        return imageFile;
      }
      
      print('❌ Unsupported image type: ${imageFile.runtimeType}');
      return null;
    } catch (e) {
      print('❌ Error in uploadImage: $e');
      return null;
    }
  }



  // Send image message

  Future<void> sendImageMessage(String chatId, String senderId, File imageFile) async {

    try {

      final imageUrl = await uploadImage(imageFile, chatId);



      final messageId = const Uuid().v4();

      final message = Message(

        id: messageId,

        senderId: senderId,

        text: '📷 Image',

        imageUrl: imageUrl,

        timestamp: Timestamp.now(),

      );



      await _firestore

          .collection('chats')

          .doc(chatId)

          .collection('messages')

          .doc(messageId)

          .set(message.toFirestore());



      // Update chat's last message

      await _updateLastMessage(chatId, '📷 Image');

    } catch (e) {

      throw Exception('Failed to send image: $e');

    }

  }



  // Pick image from gallery or camera

  Future<File?> pickImage({bool fromCamera = false}) async {

    final pickedFile = await _imagePicker.pickImage(

      source: fromCamera ? ImageSource.camera : ImageSource.gallery,

      imageQuality: 70,

    );



    if (pickedFile != null) {

      return File(pickedFile.path);

    }

    return null;

  }



  // Update typing indicator

  Future<void> setTypingIndicator(String chatId, String userId, bool isTyping) async {

    final typingRef = _firestore

        .collection('chats')

        .doc(chatId)

        .collection('typing')

        .doc(userId);



    if (isTyping) {

      await typingRef.set({

        'isTyping': true,

        'timestamp': Timestamp.now(),

      });



      // Auto-remove typing indicator after 3 seconds

      Future.delayed(const Duration(seconds: 3), () {

        typingRef.delete();

      });

    } else {

      await typingRef.delete();

    }

  }



  // Get typing indicators for a chat

  Stream<List<String>> getTypingUsers(String chatId, String currentUserId) {

    return _firestore

        .collection('chats')

        .doc(chatId)

        .collection('typing')

        .snapshots()

        .map((snapshot) => snapshot.docs

            .where((doc) => doc.id != currentUserId)

            .map((doc) => doc.id)

            .toList());

  }



  // Create a new chat - FIXED: Uses unique deterministic chatId
  Future<String> createChat(String name, List<String> participants) async {
    // Sort participants to ensure consistent chatId
    final sortedParticipants = List<String>.from(participants)..sort();
    final chatId = sortedParticipants.join('_'); // e.g., "uid1_uid2"
    
    final chatRef = _firestore.collection('chats').doc(chatId);
    
    // Check if chat already exists
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      // Create new chat only if it doesn't exist
      final chat = Chat(
        id: chatId,
        name: name,
        participants: participants,
      );
      
      await chatRef.set(chat.toFirestore());
    }
    
    return chatId;
  }



  // Update last message in chat

  Future<void> _updateLastMessage(String chatId, String lastMessage) async {

    await _firestore.collection('chats').doc(chatId).update({

      'lastMessage': lastMessage,

      'lastMessageTime': Timestamp.now(),

    });

  }



  // Delete message

  Future<void> deleteMessage(String chatId, String messageId) async {

    await _firestore

        .collection('chats')

        .doc(chatId)

        .collection('messages')

        .doc(messageId)

        .delete();

  }

}

