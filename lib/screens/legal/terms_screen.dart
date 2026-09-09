import 'package:flutter/material.dart';
import '../../design/tribe_design.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                title: Text('Terms of Service', style: t.display(size: 18, color: t.milk)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms of Service',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '1. Acceptance of Terms',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'By using TRIBE, you agree to these terms. If you do not agree, please do not use our service.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '2. User Conduct',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You agree to use TRIBE for lawful purposes only. You must not post content that is illegal, harmful, threatening, abusive, or otherwise objectionable.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '3. Content Ownership',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You retain ownership of content you post to TRIBE. By posting, you grant us a license to use, display, and distribute your content on our platform.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '4. Account Security',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You are responsible for maintaining the confidentiality of your account credentials. Notify us immediately of any unauthorized use.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '5. Termination',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We reserve the right to suspend or terminate your account at any time for violation of these terms.',
                        style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '6. Changes to Terms',
                        style: t.body(size: 14, weight: FontWeight.w700, color: t.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We may update these terms from time to time. Continued use of TRIBE after changes constitutes acceptance of the new terms.',
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
