import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/painting.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../widgets/onboarding/onboarding_page_indicator.dart';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding/1'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon
              Icon(
                Icons.camera_alt_rounded,
                size: 64,
                color: AppTheme.brandPrimary,
              ),
              const SizedBox(height: 40),
              // Headline
              Text(
                'Add a profile photo',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Body
              Text(
                'Show your face, or keep it mysterious. You can change this anytime.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Avatar preview
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null),
                      child: _pickedImage == null && user?.avatarUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
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
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Next button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                        }
                        return; // Stop navigation if upload fails
                      }
                    }
                    if (context.mounted) context.go('/onboarding/3');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Skip button
              TextButton(
                onPressed: () => context.go('/onboarding/3'),
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Page indicator
              const OnboardingPageIndicator(activeIndex: 1),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
