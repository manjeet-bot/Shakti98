import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberFormScreen extends StatefulWidget {
  final DocumentSnapshot? member;

  const MemberFormScreen({super.key, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _nameController = TextEditingController();
  final _serviceNumberController = TextEditingController();
  final _rankController = TextEditingController();
  final _coyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  
  DateTime? _enlistmentDate;
  DateTime? _retirementDate;
  bool _isActive = true;
  bool _isLoading = false;

  // Updated ranks list
  final List<String> _ranks = [
    'AV', 'SPR', 'NK', 'HAV', 'NB/SUB', 'SUB', 'SM',
    'H/LT', 'H/CAPT', 'LT', 'CAPT', 'MAJ', 'LT COL', 'COL',
  ];

  // Updated companies list
  final List<String> _companies = [
    'RHQ', '72 FD COY', '73 FD COY', '369 FD COY', '685 FD PARK COY',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _loadMemberData();
    }
  }

  void _loadMemberData() {
    final data = widget.member!.data() as Map<String, dynamic>;
    _nameController.text = data['name'] ?? '';
    _serviceNumberController.text = data['serviceNumber'] ?? '';
    _rankController.text = data['rank'] ?? '';
    _coyController.text = data['coy'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _emailController.text = data['email'] ?? '';
    _addressController.text = data['address'] ?? '';
    _emergencyContactController.text = data['emergencyContact'] ?? '';
    _bloodGroupController.text = data['bloodGroup'] ?? '';
    _isActive = data['isActive'] ?? true;
    
    if (data['enlistmentDate'] != null) {
      _enlistmentDate = (data['enlistmentDate'] as Timestamp).toDate();
    }
    if (data['retirementDate'] != null) {
      _retirementDate = (data['retirementDate'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceNumberController.dispose();
    _rankController.dispose();
    _coyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final memberData = {
        'name': _nameController.text.trim(),
        'serviceNumber': _serviceNumberController.text.trim(),
        'rank': _rankController.text.trim(),
        'coy': _coyController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'enlistmentDate': _enlistmentDate != null ? Timestamp.fromDate(_enlistmentDate!) : null,
        'retirementDate': _retirementDate != null ? Timestamp.fromDate(_retirementDate!) : null,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.member == null) {
        // Add new member
        memberData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('members').add(memberData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member added successfully!'),
              backgroundColor: Color(0xFF9C27B0),
            ),
          );
        }
      } else {
        // Update existing member
        await _firestore.collection('members').doc(widget.member!.id).update(memberData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member updated successfully!'),
              backgroundColor: Color(0xFF9C27B0),
            ),
          );
        }
      }

      // Safe navigation with delay to avoid navigator locked error
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(widget.member == null ? 'Add Member' : 'Edit Member'),
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
              ]),
              
              const SizedBox(height: 24),
              
              // Contact Information
              _buildSection('Contact Information', [
                _buildTextField(_phoneController, 'Phone Number', Icons.phone, TextInputType.phone),
                _buildTextField(_emailController, 'Email', Icons.email, TextInputType.emailAddress),
                _buildTextField(_addressController, 'Address', Icons.location_on),
                _buildTextField(_emergencyContactController, 'Emergency Contact', Icons.contact_phone, TextInputType.phone),
              ]),
              
              const SizedBox(height: 24),
              
              // Service Information
              _buildSection('Service Information', [
                _buildDateField('Enlistment Date', _enlistmentDate, (date) {
                  setState(() {
                    _enlistmentDate = date;
                  });
                }),
                _buildDateField('Retirement Date', _retirementDate, (date) {
                  setState(() {
                    _retirementDate = date;
                  });
                }),
                SwitchListTile(
                  title: const Text('Active Status', style: TextStyle(color: Colors.white)),
                  subtitle: Text(_isActive ? 'Currently Active' : 'Inactive', 
                      style: const TextStyle(color: Color(0xFF888888))),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeColor: const Color(0xFF9C27B0),
                ),
              ]),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Member',
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
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
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

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2050),
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFFFFD700)),
            prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF9C27B0)),
            filled: true,
            fillColor: const Color(0xFF0A0A0A),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF9C27B0)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            date != null ? '${date.day}/${date.month}/${date.year}' : 'Select Date',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
