import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UserHighlightsScreen extends StatefulWidget {
  final String? userId;
  final String? displayName;

  const UserHighlightsScreen({
    super.key,
    this.userId,
    this.displayName,
  });

  @override
  State<UserHighlightsScreen> createState() => _UserHighlightsScreenState();
}

class _UserHighlightsScreenState extends State<UserHighlightsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _highlights = [];
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == null || widget.userId == _auth.currentUser?.uid;
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    try {
      print('🔍 Loading highlights...');
      final targetUserId = widget.userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) {
        print('❌ No target user ID');
        return;
      }

      print('📱 Querying highlights for user: $targetUserId');
      final highlightsSnapshot = await _firestore
          .collection('user_highlights')
          .where('userId', isEqualTo: targetUserId)
          .orderBy('createdAt', descending: true)
          .get();

      print('📊 Found ${highlightsSnapshot.docs.length} highlights');
      _highlights = highlightsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('📝 Highlight: ${data['caption']} - Image: ${data['imageUrl'].isNotEmpty}');
        return {
          'id': doc.id,
          'imageUrl': data['imageUrl'] ?? '',
          'caption': data['caption'] ?? '',
          'createdAt': data['createdAt'] ?? Timestamp.now(),
          'likes': List<String>.from(data['likes'] ?? []),
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Unknown',
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
      print('✅ Highlights loaded successfully');
    } catch (e) {
      print('❌ Error loading highlights: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addHighlight() async {
    if (!_isCurrentUser) return;

    try {
      print('🚀 Starting highlight upload...');
      
      // First try without image to test connection
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No current user');
        return;
      }

      print('👤 Current user: ${currentUser.uid}');

      // Show caption dialog
      final caption = await _showCaptionDialog();
      if (caption == null) {
        print('❌ No caption provided');
        return;
      }

      print('📝 Caption: $caption');

      // Save simple test data first
      final highlightData = {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? currentUser.email ?? 'Unknown',
        'imageUrl': '', // Empty for now
        'caption': caption.trim(),
        'createdAt': Timestamp.now(),
        'likes': [],
      };

      print('💾 Saving test highlight data...');
      final docRef = await _firestore.collection('user_highlights').add(highlightData);
      print('✅ Test highlight saved with ID: ${docRef.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test highlight added! ID: ${docRef.id}'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        ),
      );

      // Reload highlights
      _loadHighlights();

      // Now try with image
      _addImageHighlight();

    } catch (e) {
      print('❌ Error adding highlight: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC143C),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _addImageHighlight() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 60,
      );

      if (image == null) return;

      // Convert image to base64
      final bytes = await image.readAsBytes();
      print('Image size: ${bytes.length} bytes');
      
      if (bytes.length > 500000) { // 500KB limit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large. Max 500KB allowed.'),
            backgroundColor: Color(0xFFDC143C),
          ),
        );
        return;
      }
      
      final base64String = base64Encode(bytes);
      print('Base64 length: ${base64String.length}');

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Save with image
      final highlightData = {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? currentUser.email ?? 'Unknown',
        'imageUrl': 'data:image/jpeg;base64,$base64String',
        'caption': 'Photo highlight',
        'createdAt': Timestamp.now(),
        'likes': [],
      };

      print('Saving image highlight...');
      await _firestore.collection('user_highlights').add(highlightData);
      print('Image highlight saved successfully!');

      _loadHighlights();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image highlight added successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      print('Error adding image highlight: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC143C),
        ),
      );
    }
  }

  Future<String?> _showCaptionDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Add Caption',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter caption...',
            hintStyle: TextStyle(color: Color(0xFF6C757D)),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4CAF50)),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text(
              'Add',
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(String highlightId, List<String> currentLikes) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final userLiked = currentLikes.contains(currentUser.uid);
      final updatedLikes = List<String>.from(currentLikes);

      if (userLiked) {
        updatedLikes.remove(currentUser.uid);
      } else {
        updatedLikes.add(currentUser.uid);
      }

      await _firestore.collection('user_highlights').doc(highlightId).update({
        'likes': updatedLikes,
      });

      _loadHighlights();
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating like: ${e.toString()}'),
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
        title: Text(
          _isCurrentUser ? 'My Highlights' : '${widget.displayName ?? "User"}\'s Highlights',
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addHighlight,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : _highlights.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: const Color(0xFF6C757D),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isCurrentUser ? 'No highlights yet' : 'No highlights to show',
                        style: const TextStyle(
                          color: Color(0xFF6C757D),
                          fontSize: 16,
                        ),
                      ),
                      if (_isCurrentUser) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _addHighlight,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add Your First Highlight'),
                        ),
                      ],
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _highlights.length,
                  itemBuilder: (context, index) {
                    final highlight = _highlights[index];
                    return _buildHighlightCard(highlight);
                  },
                ),
    );
  }

  Widget _buildHighlightCard(Map<String, dynamic> highlight) {
    final isLiked = highlight['likes'].contains(_auth.currentUser?.uid);
    final likesCount = highlight['likes'].length;

    return GestureDetector(
      onTap: () => _showHighlightDetail(highlight),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Image
              _buildHighlightImage(highlight['imageUrl']),
              
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Like button
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _toggleLike(highlight['id'], highlight['likes']),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          likesCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildHighlightImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imageUrl.split(',')[1]),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF1A1A2E),
            child: const Icon(
              Icons.broken_image,
              color: Color(0xFF6C757D),
            ),
          );
        },
      );
    } else if (imageUrl.isEmpty) {
      // Empty image - show placeholder
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Icon(
          Icons.image,
          color: Color(0xFF6C757D),
          size: 40,
        ),
      );
    }
    
    return Container(
      color: const Color(0xFF1A1A2E),
      child: const Icon(
        Icons.broken_image,
        color: Color(0xFF6C757D),
      ),
    );
  }

  void _showHighlightDetail(Map<String, dynamic> highlight) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF4CAF50),
                      child: Text(
                        highlight['userName'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        highlight['userName'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Image
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildHighlightImage(highlight['imageUrl']),
                  ),
                ),
              ),
              
              // Caption
              if (highlight['caption'].isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    highlight['caption'],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
              
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleLike(highlight['id'], highlight['likes']),
                      child: Row(
                        children: [
                          Icon(
                            highlight['likes'].contains(_auth.currentUser?.uid)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: highlight['likes'].contains(_auth.currentUser?.uid)
                                ? Colors.red
                                : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${highlight['likes'].length} likes',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
