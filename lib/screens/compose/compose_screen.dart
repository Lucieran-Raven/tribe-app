import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/rant_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/rant_service.dart';
import '../../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/obsidian_tokens.dart';
import '../../widgets/obsidian/obsidian_button.dart';
import '../../widgets/obsidian/obsidian_chip.dart';
import '../../widgets/obsidian/obsidian_snackbar.dart';

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
            ObsidianSnackbar.show(context, 'Image upload failed: $e', error: true);
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
        ObsidianSnackbar.show(context, 'Failed to post: $e', error: true);
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        border: Border(top: BorderSide(color: ObsidianTokens.lineStrong(false))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: ObsidianTokens.grey700,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create post',
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ObsidianTokens.milk,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: ObsidianTokens.inkDim, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ObsidianTokens.bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ObsidianTokens.line(false)),
              boxShadow: ObsidianTokens.clayOutSmDark,
            ),
            child: TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 500,
              onChanged: (value) => setState(() => _rantText = value),
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: ObsidianTokens.ink,
              ),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: ObsidianTokens.inkFaint,
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_rantText.length}/500',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ObsidianTokens.inkFaint,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ObsidianChip(
            label: _pickedImage != null ? 'Photo attached' : 'Add photo',
            icon: Icons.image_outlined,
            active: _pickedImage != null,
            onTap: _isPosting ? null : () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, maxHeight: 1280, imageQuality: 80);
              if (pickedFile != null) {
                setState(() => _pickedImage = File(pickedFile.path));
              }
            },
          ),
          if (_pickedImage != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_pickedImage!, height: 128, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ObsidianButton(
                  label: 'Cancel',
                  kind: ObsidianButtonKind.secondary,
                  onPressed: _isPosting ? null : () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ObsidianButton(
                  label: 'Post',
                  onPressed: _rantText.trim().isEmpty || _rantText.length > 500 || _isPosting
                      ? null
                      : _postRant,
                  loading: _isPosting,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
