import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/rant_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/rant_service.dart';
import '../../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final TextEditingController _controller = TextEditingController();
  String _rantText = '';
  bool _isPosting = false;
  File? _pickedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _rantText = _controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _postRant() async {
    final content = _rantText.trim();
    if (content.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _isPosting = true);

    try {
      final user = authState.user;
      final docRef = FirebaseFirestore.instance.collection('rants').doc();
      final postId = docRef.id;
      
      String? imageUrl;
      if (_pickedImage != null) {
        try {
          imageUrl = await StorageService().uploadPostImage(_pickedImage!, postId);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
          }
          if (mounted) setState(() => _isPosting = false);
          return; // Do not create the post if the image upload fails
        }
      }

      final rant = RantModel(
        rantId: postId,
        userId: user.userId,
        handle: user.handle ?? 'anonymous',
        avatarUrl: user.avatarUrl,
        content: content,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      await RantService().createRant(rant);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Post',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 10,
            minLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: "What's on your mind?",
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          if (_pickedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_pickedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _pickedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _isPosting ? null : () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, maxHeight: 1280, imageQuality: 80);
                  if (pickedFile != null) {
                    setState(() => _pickedImage = File(pickedFile.path));
                  }
                },
              ),
              Text('${_rantText.length}/500', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isPosting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _rantText.trim().isEmpty || _rantText.length > 500 || _isPosting
                    ? null
                    : _postRant,
                child: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
