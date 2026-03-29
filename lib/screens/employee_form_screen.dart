import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeFormScreen extends StatefulWidget {
  final DocumentSnapshot? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _nameController = TextEditingController();
  final _armyNumberController = TextEditingController();
  final _rankController = TextEditingController();
  final _unitController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  DateTime? _enlistmentDate;
  DateTime? _retirementDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _loadEmployeeData();
    }
  }

  void _loadEmployeeData() {
    final data = widget.employee!.data() as Map<String, dynamic>;
    _nameController.text = data['name'] ?? '';
    _armyNumberController.text = data['armyNumber'] ?? '';
    _rankController.text = data['rank'] ?? '';
    _unitController.text = data['unit'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _emailController.text = data['email'] ?? '';
    _addressController.text = data['address'] ?? '';
    _emergencyContactController.text = data['emergencyContact'] ?? '';
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
    _armyNumberController.dispose();
    _rankController.dispose();
    _unitController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final employeeData = {
        'name': _nameController.text.trim(),
        'armyNumber': _armyNumberController.text.trim(),
        'rank': _rankController.text.trim(),
        'unit': _unitController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'enlistmentDate': _enlistmentDate != null ? Timestamp.fromDate(_enlistmentDate!) : null,
        'retirementDate': _retirementDate != null ? Timestamp.fromDate(_retirementDate!) : null,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.employee == null) {
        // Add new employee
        employeeData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('employees').add(employeeData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee added successfully!'),
            backgroundColor: Color(0xFF9C27B0),
          ),
        );
      } else {
        // Update existing employee
        await _firestore.collection('employees').doc(widget.employee!.id).update(employeeData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee updated successfully!'),
            backgroundColor: Color(0xFF9C27B0),
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC143C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
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
                _buildTextField(_armyNumberController, 'Army Number', Icons.military_tech),
                _buildTextField(_rankController, 'Rank', Icons.grade),
              ]),
              
              const SizedBox(height: 24),
              
              // Contact Information
              _buildSection('Contact Information', [
                _buildTextField(_phoneController, 'Phone Number', Icons.phone, TextInputType.phone),
                _buildTextField(_emailController, 'Email', Icons.email, TextInputType.emailAddress),
                _buildTextField(_addressController, 'Address', Icons.location_on),
                _buildTextField(_emergencyContactController, 'Emergency Contact', Icons.contact_phone),
              ]),
              
              const SizedBox(height: 24),
              
              // Service Information
              _buildSection('Service Information', [
                _buildTextField(_unitController, 'Unit', Icons.group),
                _buildDateField('Enlistment Date', _enlistmentDate, (date) => _enlistmentDate = date),
                _buildDateField('Retirement Date', _retirementDate, (date) => _retirementDate = date),
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
                  onPressed: _saveEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Employee',
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
