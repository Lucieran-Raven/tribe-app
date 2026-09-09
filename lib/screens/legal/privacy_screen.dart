import 'package:flutter/material.dart';
import '../../design/tribe_design.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = const TribeTheme(true);
    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                leading: IconBtn(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                title: Text('Privacy Policy', style: t.display(size: 18, color: t.milk)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '1. Information We Collect',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We collect information you provide directly, such as your name, email, profile picture, and content you post. We also collect usage data and device information.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '2. How We Use Your Information',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We use your information to provide, maintain, and improve TRIBE. This includes personalizing your experience, communicating with you, and analyzing usage patterns.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '3. Data Storage',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your data is stored securely using Firebase (Google Cloud Platform). We implement appropriate security measures to protect your information.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '4. Data Sharing',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We do not sell your personal information. We may share data with service providers who perform services on our behalf, such as Firebase.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '5. Your Rights',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have the right to access, update, or delete your personal information. You can delete your account at any time through the profile settings.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '6. Changes to This Policy',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We may update this privacy policy from time to time. We will notify you of any material changes by posting the new policy on this page.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                    ],
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
