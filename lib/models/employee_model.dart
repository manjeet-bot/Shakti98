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
      department: data['department'] ?? '',
      retirementDate: (data['retirementDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      phone: data['phone'],
      email: data['email'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'armyNumber': armyNumber,
      'name': name,
      'rank': rank,
      'department': department,
      'retirementDate': Timestamp.fromDate(retirementDate),
      'imageUrl': imageUrl,
      'phone': phone,
      'email': email,
    };
  }

  Employee copyWith({
    String? id,
    String? armyNumber,
    String? name,
    String? rank,
    String? department,
    DateTime? retirementDate,
    String? imageUrl,
    String? phone,
    String? email,
  }) {
    return Employee(
      id: id ?? this.id,
      armyNumber: armyNumber ?? this.armyNumber,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      department: department ?? this.department,
      retirementDate: retirementDate ?? this.retirementDate,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
