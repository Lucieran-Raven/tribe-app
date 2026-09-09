import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/rant_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/rant_service.dart';
import '../../services/storage_service.dart';
import '../../design/tribe_design.dart';
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
          if (mounted) {
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
    final t = const TribeTheme(true);
    return TribeThemeScope(
      theme: t,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: t.bg1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          border: Border(top: BorderSide(color: t.lineStrong)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // grabber
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(4))),
              // header row
              Row(children: [
                Expanded(child: Text('Create post', style: t.display(size: 17, color: t.milk))),
                IconBtn(icon: Icons.close, onTap: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 14),
              ClayInput(
                controller: _controller,
                hint: "What's on your mind?",
                maxLines: 4,
                maxLength: 500,
              ),
              Align(alignment: Alignment.centerRight, child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text('${_rantText.length}/500', style: t.caption(size: 11)))),
              Align(alignment: Alignment.centerLeft, child: TribeChip(
                icon: Icons.image_outlined,
                label: _pickedImage != null ? 'Photo attached' : 'Add photo',
                onTap: _isPosting ? null : () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, maxHeight: 1280, imageQuality: 80);
                  if (pickedFile != null) {
                    setState(() => _pickedImage = File(pickedFile.path));
                  }
                })),
              if (_pickedImage != null) ...[
                const SizedBox(height: 16),
                ClampedCoverImage(image: FileImage(_pickedImage!), maxHeight: 240),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ClayButtonSecondary(label: 'Cancel', onTap: _isPosting ? null : () => Navigator.pop(context))),
                const SizedBox(width: 10),
                Expanded(child: ClayButtonPrimary(label: 'Post', loading: _isPosting,
                  onTap: _rantText.trim().isEmpty || _rantText.length > 500 || _isPosting ? null : _postRant)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
