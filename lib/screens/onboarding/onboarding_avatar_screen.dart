import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/tribe_design.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/avatar_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingAvatarScreen extends ConsumerStatefulWidget {
  const OnboardingAvatarScreen({super.key});

  @override
  ConsumerState<OnboardingAvatarScreen> createState() => _OnboardingAvatarScreenState();
}

class _OnboardingAvatarScreenState extends ConsumerState<OnboardingAvatarScreen> {
  File? _pickedImage;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF8F8A8B), size: 24),
                    onPressed: () => context.go('/onboarding/1'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '02 / AVATAR',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: const Color(0xFF8F8A8B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Centered content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar circle
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1B1819),
                            border: Border.all(color: const Color(0xFF2B2627), width: 1),
                          ),
                          child: ClipOval(
                            child: _pickedImage != null
                                ? Image.file(_pickedImage!, fit: BoxFit.cover, width: 120, height: 120)
                                : (user?.avatarUrl != null
                                    ? Image.network(
                                        user!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF8F8A8B)),
                                      )
                                    : const Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF8F8A8B))),
                          ),
                        ),
                        // Camera FAB
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                try {
                                  final cropped = await AvatarCropper.crop(File(pickedFile.path), context);
                                  if (cropped != null && mounted) {
                                    setState(() => _pickedImage = cropped);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Toast.error(context, 'Failed to crop image: $e');
                                  }
                                }
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF6D001A),
                                border: Border.all(color: const Color(0xFF000000), width: 2),
                              ),
                              child: const Icon(Icons.add, color: Color(0xFFFFFFFF), size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Headline
                    Text(
                      'PICK A FACE.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.anton(fontSize: 40, height: 1.05, color: const Color(0xFFFFFFFF)),
                    ),
                    const SizedBox(height: 12),
                    // Subtext
                    SizedBox(
                      width: 280,
                      child: Text(
                        "It doesn't have to be your face.\nJust yours.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 15, height: 1.46, color: const Color(0xFF8F8A8B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Next button
                  GestureDetector(
                    onTap: _isUploading
                        ? null
                        : () async {
                            setState(() => _isUploading = true);
                            final authState = ref.read(authProvider);
                            if (authState is AuthAuthenticated && _pickedImage != null) {
                              try {
                                final newAvatarUrl = await StorageService().uploadAvatar(_pickedImage!, authState.user.userId);
                                await FirebaseFirestore.instance.collection('users').doc(authState.user.userId).update({'avatarUrl': newAvatarUrl});
                                PaintingBinding.instance.imageCache.clear();
                                final freshDoc = await FirebaseFirestore.instance.collection('users').doc(authState.user.userId).get();
                                if (freshDoc.exists) {
                                  ref.read(authProvider.notifier).updateUser(UserModel.fromJson(freshDoc.data() as Map<String, dynamic>));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Toast.error(context, 'Upload failed: $e');
                                }
                                setState(() => _isUploading = false);
                                return;
                              }
                            }
                            if (context.mounted) {
                              setState(() => _isUploading = false);
                              context.go('/onboarding/3');
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isUploading ? const Color(0xFF1B1819) : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: _isUploading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF8F8A8B), strokeWidth: 2))
                            : Text('NEXT', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.4, color: const Color(0xFF0E0C0D))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Skip button
                  GestureDetector(
                    onTap: () => context.go('/onboarding/3'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      alignment: Alignment.center,
                      child: Text('SKIP FOR NOW', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.4, color: const Color(0xFF8F8A8B))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
