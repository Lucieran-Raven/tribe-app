import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/painting.dart';
import '../../config/theme.dart';
import '../../config/obsidian_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../widgets/obsidian/obsidian_dots.dart';
import '../../widgets/obsidian/obsidian_button.dart';
import '../../widgets/obsidian/obsidian_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingAvatarScreen extends ConsumerStatefulWidget {
  const OnboardingAvatarScreen({super.key});

  @override
  ConsumerState<OnboardingAvatarScreen> createState() => _OnboardingAvatarScreenState();
}

class _OnboardingAvatarScreenState extends ConsumerState<OnboardingAvatarScreen> {
  File? _pickedImage;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: ObsidianTokens.bg0,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Row(children: [
              SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.arrow_back, color: ObsidianTokens.inkDim), onPressed: () => context.go('/onboarding/1'))),
              const Expanded(child: Center(child: ObsidianDots(count: 5, active: 1))),
              const SizedBox(width: 40),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  Text(
                    'Pick a face',
                    style: GoogleFonts.manrope(fontSize: 19, fontWeight: FontWeight.w800, color: ObsidianTokens.milk),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "It doesn't have to be your face. Just yours.",
                    style: GoogleFonts.inter(fontSize: 13, color: ObsidianTokens.inkDim, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          maxHeight: 512,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setState(() => _pickedImage = File(pickedFile.path));
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ObsidianTokens.bg2,
                              border: Border.all(color: ObsidianTokens.line(false)),
                              boxShadow: ObsidianTokens.clayOutDark,
                            ),
                            alignment: Alignment.center,
                            child: _pickedImage != null
                                ? ClipOval(child: Image.file(_pickedImage!, fit: BoxFit.cover))
                                : (user?.avatarUrl != null
                                    ? ClipOval(child: Image.network(user!.avatarUrl!, fit: BoxFit.cover))
                                    : Icon(Icons.photo_camera_outlined, size: 26, color: ObsidianTokens.inkFaint)),
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [ObsidianTokens.milk, ObsidianTokens.milkDim]),
                                boxShadow: ObsidianTokens.clayMilkOutDark,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.photo_camera, size: 13, color: ObsidianTokens.bg0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ObsidianButton(
                    label: 'Next',
                    onPressed: () async {
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
                            ObsidianSnackbar.show(context, 'Upload failed: $e', error: true);
                          }
                          return;
                        }
                      }
                      await Future.delayed(const Duration(milliseconds: 50));
                      if (context.mounted) context.go('/onboarding/3');
                    },
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => context.go('/onboarding/3'),
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.inter(fontSize: 14, color: ObsidianTokens.inkFaint, fontWeight: FontWeight.w600),
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
}
