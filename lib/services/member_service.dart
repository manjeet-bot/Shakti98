import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all members stream
  Stream<List<Member>> getAllMembers() {
    return _firestore
        .collection('members')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromFirestore(doc))
            .toList());
  }

  // Get active members only
  Stream<List<Member>> getActiveMembers() {
    return _firestore
        .collection('members')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromFirestore(doc))
            .toList());
  }

  // Get members by company
  Stream<List<Member>> getMembersByCompany(String coy) {
    return _firestore
        .collection('members')
        .where('coy', isEqualTo: coy)
        .where('isActive', isEqualTo: true)
        .orderBy('rank')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromFirestore(doc))
            .toList());
  }

  // Get member by ID
  Future<Member?> getMemberById(String memberId) async {
    try {
      final doc = await _firestore.collection('members').doc(memberId).get();
      if (doc.exists) {
        return Member.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting member: $e');
      return null;
    }
  }

  // Add new member
  Future<String?> addMember(Member member) async {
    try {
      final docRef = await _firestore.collection('members').add(member.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding member: $e');
      return null;
    }
  }

  // Update member
  Future<void> updateMember(String memberId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('members').doc(memberId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating member: $e');
      throw Exception('Failed to update member: $e');
    }
  }

  // Delete member
  Future<void> deleteMember(String memberId) async {
    try {
      await _firestore.collection('members').doc(memberId).delete();
    } catch (e) {
      print('Error deleting member: $e');
      throw Exception('Failed to delete member: $e');
    }
  }

  // Toggle member status
  Future<void> toggleMemberStatus(String memberId, bool isActive) async {
    try {
      await _firestore.collection('members').doc(memberId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling member status: $e');
      throw Exception('Failed to update member status: $e');
    }
  }

  // Search members
  Future<List<Member>> searchMembers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('members')
          .where('isActive', isEqualTo: true)
          .get();

      final members = snapshot.docs
          .map((doc) => Member.fromFirestore(doc))
          .where((member) =>
              member.name.toLowerCase().contains(query.toLowerCase()) ||
              member.rank.toLowerCase().contains(query.toLowerCase()) ||
              member.coy.toLowerCase().contains(query.toLowerCase()) ||
              member.serviceNumber.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return members;
    } catch (e) {
      print('Error searching members: $e');
      return [];
    }
  }

  // Get member statistics
  Future<Map<String, int>> getMemberStatistics() async {
    try {
      final snapshot = await _firestore.collection('members').get();
      
      int total = snapshot.docs.length;
      int active = snapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] == true)
          .length;
      int inactive = total - active;

      // Count by company
      final Map<String, int> companyCounts = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final coy = data['coy'] as String? ?? 'Unknown';
        companyCounts[coy] = (companyCounts[coy] ?? 0) + 1;
      }

      return {
        'total': total,
        'active': active,
        'inactive': inactive,
        ...companyCounts,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
      };
    }
  }
}
