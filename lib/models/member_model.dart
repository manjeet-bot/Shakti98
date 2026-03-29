import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String id;
  final String name;
  final String rank;
  final String coy;
  final String bloodGroup;
  final String serviceNumber;
  final String? photoUrl;
  final String? profileImageUrl;
  final Timestamp? createdAt;
  final Timestamp? lastActive;
  final bool isOnline;
  final String? chatId;

  Member({
    required this.id,
    required this.name,
    required this.rank,
    required this.coy,
    required this.bloodGroup,
    required this.serviceNumber,
    this.photoUrl,
    this.profileImageUrl,
    this.createdAt,
    this.lastActive,
    this.isOnline = false,
    this.chatId,
  });

  factory Member.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      name: data['name'] ?? '',
      rank: data['rank'] ?? '',
      coy: data['coy'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      serviceNumber: data['serviceNumber'] ?? '',
      photoUrl: data['photoUrl'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: data['createdAt'] as Timestamp?,
      lastActive: data['lastActive'] as Timestamp?,
      isOnline: data['isOnline'] ?? false,
      chatId: data['chatId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rank': rank,
      'coy': coy,
      'bloodGroup': bloodGroup,
      'serviceNumber': serviceNumber,
      'photoUrl': photoUrl,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lastActive': lastActive ?? FieldValue.serverTimestamp(),
      'isOnline': isOnline,
      'chatId': chatId,
    };
  }

  Member copyWith({
    String? id,
    String? name,
    String? rank,
    String? coy,
    String? bloodGroup,
    String? serviceNumber,
    String? photoUrl,
    String? profileImageUrl,
    Timestamp? createdAt,
    Timestamp? lastActive,
    bool? isOnline,
    String? chatId,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      coy: coy ?? this.coy,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      serviceNumber: serviceNumber ?? this.serviceNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
      chatId: chatId ?? this.chatId,
    );
  }
}
