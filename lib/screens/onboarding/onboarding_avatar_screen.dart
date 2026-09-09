import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../design/tribe_design.dart';
import '../../providers/auth_provider.dart';
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
    final t = const TribeTheme(true);

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              // Header row with indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconBtn(icon: Icons.arrow_back, onTap: () => context.go('/onboarding/1')),
                    const OnboardingPageIndicator(activeIndex: 1),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              // Centered cluster
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Headline
                        Text(
                          'Pick a face',
                          style: t.display(size: 19, color: t.milk),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        // Subtext
                        Text(
                          "It doesn't have to be your face. Just yours.",
                          style: t.body(size: 13, weight: FontWeight.w500, color: t.inkDim),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        // Avatar preview
                        GestureDetector(
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
                                  color: t.bg2,
                                  border: Border.all(color: t.line),
                                  boxShadow: t.clayOut,
                                ),
                                alignment: Alignment.center,
                                child: _pickedImage != null
                                    ? CircleAvatar(
                                        radius: 50,
                                        backgroundImage: FileImage(_pickedImage!),
                                      )
                                    : (user?.avatarUrl != null
                                        ? CircleAvatar(
                                            radius: 50,
                                            backgroundImage: NetworkImage(user!.avatarUrl!),
                                          )
                                        : Icon(Icons.camera_alt_outlined, size: 26, color: t.inkFaint)),
                              ),
                              Positioned(
                                bottom: -4,
                                right: -4,
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
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [t.milk, t.milkDim], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                      shape: BoxShape.circle,
                                      boxShadow: t.clayMilkOut,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.camera_alt, size: 13, color: t.bg0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Next button
                        ClayButtonPrimary(
                          label: 'Next',
                          onTap: () async {
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
                        ),
                        const SizedBox(height: 10),
                        // Skip button
                        ClayButtonSecondary(
                          label: 'Skip for now',
                          plain: true,
                          textColor: t.inkFaint,
                          onTap: () => context.go('/onboarding/3'),
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
}
