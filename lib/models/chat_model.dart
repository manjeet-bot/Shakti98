import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String name;
  final List<String> participants;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? lastMessage;
  final String? lastMessageSender;
  final bool isGroupChat;

  Chat({
    required this.id,
    required this.name,
    required this.participants,
    this.createdAt,
    this.updatedAt,
    this.lastMessage,
    this.lastMessageSender,
    this.isGroupChat = false,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      name: data['chatName'] ?? data['name'] ?? 'Unknown Chat',
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageSender: data['lastMessageSender'] ?? '',
      isGroupChat: data['isGroupChat'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatName': name,
      'participants': participants,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'lastMessage': lastMessage ?? '',
      'lastMessageSender': lastMessageSender ?? '',
      'isGroupChat': isGroupChat,
    };
  }
}
