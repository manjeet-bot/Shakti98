import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'member_form_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _securityKeyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _members = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _authenticate() {
    final key = _securityKeyController.text.trim();
    if (key == 'SHAKTI98') {
      setState(() {
        _isAuthenticated = true;
      });
      _loadMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access granted! Welcome to Admin Panel.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid security key! Access denied.'),
          backgroundColor: Colors.red,
        ),
      );
      _securityKeyController.clear();
    }
  }

  void _loadMembers() {
    if (_isAuthenticated) {
      _firestore
          .collection('members')
          .orderBy('serviceNumber')
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _members = snapshot.docs;
          _isLoading = false;
        });
      });
    }
  }

  List<DocumentSnapshot> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    return _members.where((member) {
      final data = member.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final serviceNumber = (data['serviceNumber'] ?? '').toString().toLowerCase();
      final rank = (data['rank'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          serviceNumber.contains(_searchQuery.toLowerCase()) ||
          rank.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildAuthenticationScreen();
    }
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF0D1117),
                ],
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC143C),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.security, color: Colors.white),
                  ],
                ),
              ),
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    hintStyle: const TextStyle(color: Color(0xFF888888)),
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDC143C)),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              // Member list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFDC143C)),
                      )
                    : _filteredMembers.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Color(0xFF888888),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No members found',
                                  style: TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredMembers.length,
                            itemBuilder: (context, index) {
                              final member = _filteredMembers[index];
                              final data = member.data() as Map<String, dynamic>;
                              
                              return Card(
                                color: const Color(0xFF1A1A2E),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFDC143C),
                                    child: Text(
                                      (data['name'] ?? 'N')[0].toString().toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    data['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Service No: ${data['serviceNumber'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                      Text(
                                        'Rank: ${data['rank'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                      Text(
                                        'Status: ${data['isActive'] == true ? 'Active' : 'Inactive'}',
                                        style: TextStyle(
                                          color: data['isActive'] == true 
                                              ? const Color(0xFF4CAF50)
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Color(0xFF888888),
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Color(0xFF4CAF50)),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MemberFormScreen(member: member),
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        _deleteMember(member.id);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          // Floating action button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MemberFormScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFFDC143C),
              icon: const Icon(Icons.add),
              label: const Text('Add Member'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF0D1117),
                ],
              ),
            ),
          ),
          // Watermark
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              child: Opacity(
                opacity: 0.1,
                child: const Text(
                  'FIGHTING 58 SHAKTI 98',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC143C),
                  ),
                ),
              ),
            ),
          ),
          // Authentication content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Security icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC143C),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.security,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter Security Key',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Security key input
                  TextField(
                    controller: _securityKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter security key',
                      hintStyle: const TextStyle(color: Color(0xFF888888)),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDC143C)),
                      ),
                      prefixIcon: const Icon(Icons.key, color: Color(0xFFDC143C)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _authenticate(),
                  ),
                  const SizedBox(height: 24),
                  // Authenticate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC143C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Authenticate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text(
          'Delete Member',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this member?',
          style: TextStyle(color: Color(0xFF6C757D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6C757D)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('members').doc(memberId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member deleted successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting member: $e'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    }
  }
}
