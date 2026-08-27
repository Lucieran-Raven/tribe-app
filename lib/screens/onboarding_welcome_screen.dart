import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Onboarding Step 1 coming in Block 3',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _skipToHome(context, ref, authState),
              child: const Text('Skip to Home (Dev Only)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _skipToHome(BuildContext context, WidgetRef ref, dynamic authState) async {
    if (authState is AuthAuthenticated) {
      final user = (authState as AuthAuthenticated).user;
      
      try {
        // Update user document with dummy handle
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.userId)
            .update({'handle': 'test_user'});
        
        // Get updated user document
        final updatedDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.userId)
            .get();
        
        if (updatedDoc.exists) {
          final updatedUser = UserModel.fromJson(updatedDoc.data() as Map<String, dynamic>);
          // Update auth state with updated user
          ref.read(authProvider.notifier).updateUser(updatedUser);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}