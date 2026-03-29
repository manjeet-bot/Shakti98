import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../widgets/app_logo.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _profileImageUrl;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Widget _buildProfileImage() {
    if (_profileImageUrl == null) {
      return const Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
      );
    }

    // Check if it's a data URL (base64)
    if (_profileImageUrl!.startsWith('data:image')) {
      return ClipOval(
        child: Image.memory(
          base64Decode(_profileImageUrl!.split(',')[1]),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            );
          },
        ),
      );
    }

    // Check if it's a network URL
    if (_profileImageUrl!.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          _profileImageUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            );
          },
        ),
      );
    }

    // Local file path
    return const Icon(
      Icons.person,
      size: 40,
      color: Colors.white,
    );
  }

  Future<void> _updateProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        
        // Simple approach - save image URL directly
        String imageUrl;
        
        if (kIsWeb) {
          // For web, use data URL or name
          final bytes = await image.readAsBytes();
          imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        } else {
          // For mobile, use file path
          imageUrl = image.path;
        }
        
        // Update Firestore immediately
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'profileImageUrl': imageUrl,
          'lastActive': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC143C),
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _userData = data;
            _profileImageUrl = data['profileImageUrl'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _userData = {
              'displayName': user.displayName ?? user.email ?? 'Unknown',
              'email': user.email ?? 'No email',
              'rank': 'Not specified',
              'role': 'soldier',
              'chatId': user.uid, // Add chat ID
              'createdAt': DateTime.now(),
              'lastActive': DateTime.now(),
            };
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _userData = {
            'displayName': user.displayName ?? user.email ?? 'Unknown',
            'email': user.email ?? 'No email',
            'rank': 'Not specified',
            'role': 'soldier',
            'chatId': user.uid, // Add chat ID
            'createdAt': DateTime.now(),
            'lastActive': DateTime.now(),
          };
          _isLoading = false;
        });
      }
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
                title: const Text('Personal Details'),
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFDC143C)),
                      )
                    : _userData == null
                        ? const Center(
                            child: Text(
                              'No user data available',
                              style: TextStyle(color: Color(0xFF888888)),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Header
                                Card(
                                  color: const Color(0xFF1A1F2E),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        // Profile Photo with edit option
                                        GestureDetector(
                                          onTap: _updateProfilePhoto,
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: const Color(0xFFDC143C),
                                                ),
                                                child: _buildProfileImage(),
                                              ),
                                              // Edit icon overlay
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDC143C),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.camera_alt,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _userData!['displayName'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _userData!['email'] ?? 'No email',
                                                style: const TextStyle(
                                                  color: Color(0xFF888888),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Chat ID: ${_userData!['chatId'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  color: Color(0xFFDC143C),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Personal Information
                                _buildSection(
                                  'Personal Information',
                                  [
                                    _buildDetailItem('Full Name', _userData!['displayName'] ?? 'Not specified'),
                                    _buildDetailItem('Rank', _userData!['rank'] ?? 'Not specified'),
                                    _buildDetailItem('Role', _userData!['role'] ?? 'Not specified'),
                                    _buildDetailItem('Service Number', _userData!['serviceNumber'] ?? 'Not specified'),
                                    _buildDetailItem('Unit', _userData!['unit'] ?? 'Not specified'),
                                    _buildDetailItem('Blood Group', _userData!['bloodGroup'] ?? 'Not specified'),
                                  ],
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Account Information
                                _buildSection(
                                  'Account Information',
                                  [
                                    _buildDetailItem('User ID', _auth.currentUser?.uid ?? 'Unknown'),
                                    _buildDetailItem('Chat ID', _userData!['chatId'] ?? 'Unknown'),
                                    _buildDetailItem(
                                      'Member Since',
                                      _formatDate(_userData!['createdAt']),
                                    ),
                                    _buildDetailItem(
                                      'Last Active',
                                      _formatDate(_userData!['lastActive']),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Quick Actions
                                Card(
                                  color: const Color(0xFF1A1F2E),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Quick Actions',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_camera, color: Color(0xFFDC143C)),
                                        title: const Text(
                                          'Change Profile Photo',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF888888)),
                                        onTap: _updateProfilePhoto,
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.edit, color: Color(0xFFDC143C)),
                                        title: const Text(
                                          'Edit Profile',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF888888)),
                                        onTap: () => _showEditProfileDialog(),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.security, color: Color(0xFF4CAF50)),
                                        title: const Text(
                                          'Security Settings',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF6C757D)),
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Security settings coming soon!'),
                                              backgroundColor: Color(0xFF4CAF50),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                'FIGHTING 58 SHAKTI 98',
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

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      color: const Color(0xFF1A1F2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Unknown';
    }
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showEditProfileDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: _userData!['displayName'] ?? '');
    final _serviceNumberController = TextEditingController(text: _userData!['serviceNumber'] ?? '');
    final _rankController = TextEditingController(text: _userData!['rank'] ?? '');
    final _coyController = TextEditingController(text: _userData!['coy'] ?? '');
    final _phoneController = TextEditingController(text: _userData!['phone'] ?? '');
    final _emailController = TextEditingController(text: _userData!['email'] ?? '');
    final _addressController = TextEditingController(text: _userData!['address'] ?? '');
    final _emergencyContactController = TextEditingController(text: _userData!['emergencyContact'] ?? '');
    final _bloodGroupController = TextEditingController(text: _userData!['bloodGroup'] ?? '');
    final _postingController = TextEditingController(text: _userData!['posting'] ?? '');
    final _unitController = TextEditingController(text: _userData!['unit'] ?? '');
    
    bool _isLoading = false;
    
    // Updated ranks list
    final List<String> _ranks = ['AV', 'SPR', 'NK', 'HAV', 'NB/SUB', 'SUB', 'SM', 'H/LT', 'H/CAPT', 'LT', 'CAPT', 'MAJ', 'LT COL', 'COL'];
    
    // Updated companies list
    final List<String> _companies = ['RHQ', '72 FD COY', '73 FD COY', '369 FD COY', '685 FD PARK COY'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xFF0A0A0A),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.9,
              child: Scaffold(
                backgroundColor: const Color(0xFF0A0A0A),
                appBar: AppBar(
                  title: const Text('Edit Profile'),
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
                body: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information
                        _buildSection('Personal Information', [
                          _buildTextField(_nameController, 'Full Name', Icons.person),
                          _buildTextField(_serviceNumberController, 'Service Number', Icons.military_tech),
                          _buildDropdownField(_rankController, 'Rank', _ranks, Icons.grade),
                          _buildDropdownField(_coyController, 'Company', _companies, Icons.business),
                          _buildTextField(_bloodGroupController, 'Blood Group', Icons.bloodtype),
                          _buildTextField(_postingController, 'Posting', Icons.location_city),
                          _buildTextField(_unitController, 'Unit', Icons.flag),
                        ]),
                        
                        const SizedBox(height: 24),
                        
                        // Contact Information
                        _buildSection('Contact Information', [
                          _buildTextField(_phoneController, 'Phone Number', Icons.phone, TextInputType.phone),
                          _buildTextField(_emailController, 'Email', Icons.email, TextInputType.emailAddress),
                          _buildTextField(_addressController, 'Address', Icons.location_on),
                          _buildTextField(_emergencyContactController, 'Emergency Contact', Icons.contact_phone, TextInputType.phone),
                        ]),
                        
                        const SizedBox(height: 32),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isLoading = true);
                              try {
                                await _updateProfile(
                                  _nameController.text.trim(),
                                  _rankController.text.trim(),
                                  _serviceNumberController.text.trim(),
                                  _coyController.text.trim(),
                                  _bloodGroupController.text.trim(),
                                  _postingController.text.trim(),
                                  _unitController.text.trim(),
                                  _phoneController.text.trim(),
                                  _addressController.text.trim(),
                                  _emergencyContactController.text.trim(),
                                );
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C27B0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Save Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateProfile(String name, String rank, String serviceNumber, String company, String bloodGroup, String posting, String unit, String phone, String address, String emergencyContact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update users collection
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': name,
        'rank': rank,
        'serviceNumber': serviceNumber,
        'coy': company,
        'bloodGroup': bloodGroup,
        'posting': posting,
        'unit': unit,
        'phone': phone,
        'address': address,
        'emergencyContact': emergencyContact,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      // Update members collection
      await _firestore.collection('members').doc(user.uid).update({
        'displayName': name,
        'rank': rank,
        'serviceNumber': serviceNumber,
        'coy': company,
        'bloodGroup': bloodGroup,
        'posting': posting,
        'unit': unit,
        'phone': phone,
        'address': address,
        'emergencyContact': emergencyContact,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _userData!['displayName'] = name;
        _userData!['rank'] = rank;
        _userData!['serviceNumber'] = serviceNumber;
        _userData!['coy'] = company;
        _userData!['bloodGroup'] = bloodGroup;
        _userData!['posting'] = posting;
        _userData!['unit'] = unit;
        _userData!['phone'] = phone;
        _userData!['address'] = address;
        _userData!['emergencyContact'] = emergencyContact;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully! Admin panel updated.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: const Color(0xFFDC143C),
        ),
      );
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFFFD700)),
          prefixIcon: Icon(icon, color: const Color(0xFF9C27B0)),
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF9C27B0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(
    TextEditingController controller,
    String label,
    List<String> items,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFFFD700)),
          prefixIcon: Icon(icon, color: const Color(0xFF9C27B0)),
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF9C27B0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dropdownColor: const Color(0xFF21262D),
        style: const TextStyle(color: Colors.white),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (value) {
          controller.text = value ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }
}
