import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class UserProfileViewScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserProfileViewScreen({super.key, required this.userData});

  Widget _buildProfileImage(String? imageUrl, String displayName, {double size = 80}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // Default avatar with first letter
      return CircleAvatar(
        radius: size,
        backgroundColor: const Color(0xFF4CAF50),
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Check if it's a data URL (base64)
    if (imageUrl.startsWith('data:image')) {
      return CircleAvatar(
        radius: size,
        backgroundColor: const Color(0xFF4CAF50),
        backgroundImage: MemoryImage(base64Decode(imageUrl.split(',')[1])),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to default avatar
        },
        child: imageUrl.isEmpty ? Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ) : null,
      );
    }

    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: size,
        backgroundColor: const Color(0xFF4CAF50),
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to default avatar
        },
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Default fallback
    return CircleAvatar(
      radius: size,
      backgroundColor: const Color(0xFF4CAF50),
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(userData['displayName'] ?? 'User Profile'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              color: const Color(0xFF1A1A2E),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileImage(
                      userData['profileImageUrl'] ?? '',
                      userData['displayName'] ?? 'Unknown User',
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData['displayName'] ?? 'Unknown User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData['email'] ?? 'No email',
                      style: const TextStyle(
                        color: Color(0xFF6C757D),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userData['role'] ?? 'Not specified',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Personal Information
            _buildSection('Personal Information', [
              _buildDetailItem('Rank', userData['rank'] ?? 'Not specified'),
              _buildDetailItem('Service Number', userData['serviceNumber'] ?? 'Not specified'),
              _buildDetailItem('Company', userData['coy'] ?? 'Not specified'),
              _buildDetailItem('Blood Group', userData['bloodGroup'] ?? 'Not specified'),
              _buildDetailItem('Posting', userData['posting'] ?? 'Not specified'),
              _buildDetailItem('Unit', userData['unit'] ?? 'Not specified'),
            ]),
            
            const SizedBox(height: 24),
            
            // Contact Information
            _buildSection('Contact Information', [
              _buildDetailItem('Phone Number', userData['phone'] ?? 'Not specified'),
            ]),
          ],
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
    
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}
