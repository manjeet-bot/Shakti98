import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'member_form_screen.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  bool _showInactiveOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Members Directory'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showInactiveOnly ? Icons.toggle_on : Icons.toggle_off),
            onPressed: () {
              setState(() {
                _showInactiveOnly = !_showInactiveOnly;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Members...',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9C27B0)),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF9C27B0)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          
          // Members List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('members')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final members = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final rank = (data['rank'] ?? '').toString().toLowerCase();
                  final coy = (data['coy'] ?? '').toString().toLowerCase();
                  final isActive = data['isActive'] ?? true;
                  
                  final matchesSearch = name.contains(_searchQuery) || 
                                      rank.contains(_searchQuery) || 
                                      coy.contains(_searchQuery);
                  final matchesStatus = _showInactiveOnly ? !isActive : true;
                  
                  return matchesSearch && matchesStatus;
                }).toList();

                if (members.isEmpty) {
                  return const Center(
                    child: Text(
                      'No members found',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final data = member.data() as Map<String, dynamic>;
                    
                    return _buildMemberCard(member, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MemberFormScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF9C27B0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMemberCard(DocumentSnapshot member, Map<String, dynamic> data) {
    final isActive = data['isActive'] ?? true;
    final name = data['name'] ?? 'Unknown';
    final rank = data['rank'] ?? 'N/A';
    final coy = data['coy'] ?? 'N/A';
    final phone = data['phone'] ?? 'N/A';
    final bloodGroup = data['bloodGroup'] ?? 'N/A';

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? const Color(0xFF9C27B0) : Colors.grey,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$rank • $coy',
              style: const TextStyle(color: Color(0xFFFFD700)),
            ),
            Text(
              'Phone: $phone • Blood: $bloodGroup',
              style: const TextStyle(color: Color(0xFF888888)),
            ),
            if (!isActive)
              const Text(
                'INACTIVE',
                style: TextStyle(
                  color: Color(0xFFDC143C),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF9C27B0)),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editMember(member);
                break;
              case 'toggle_status':
                _toggleMemberStatus(member, isActive);
                break;
              case 'delete':
                _deleteMember(member);
                break;
            }
          },
          itemBuilder: (context) {
          final List<PopupMenuEntry<String>> items = [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF9C27B0)),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.block : Icons.check_circle,
                    color: isActive ? Color(0xFFDC143C) : Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
          ];
          
          // Only add delete option for admin
          if (_auth.currentUser?.email == 'admin@army.com') {
            items.add(
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Color(0xFFDC143C)),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            );
          }
          
          return items;
        },
        ),
      ),
    );
  }

  void _editMember(DocumentSnapshot member) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemberFormScreen(member: member),
      ),
    );
  }

  void _toggleMemberStatus(DocumentSnapshot member, bool currentStatus) async {
    try {
      await _firestore.collection('members').doc(member.id).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus ? 'Member deactivated' : 'Member activated',
            ),
            backgroundColor: currentStatus ? const Color(0xFFDC143C) : const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC143C),
          ),
        );
      }
    }
  }

  void _deleteMember(DocumentSnapshot member) async {
    // Check if current user is admin
    final currentUser = _auth.currentUser;
    if (currentUser?.email != 'admin@army.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admin can delete members!'),
          backgroundColor: Color(0xFFDC143C),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: const Text('Are you sure you want to delete this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFDC143C))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('members').doc(member.id).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member deleted successfully'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting member: $e'),
              backgroundColor: const Color(0xFFDC143C),
            ),
          );
        }
      }
    }
  }
}
