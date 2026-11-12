import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: _NoGlowScrollBehavior(),
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF8F8A8B)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '01 / LEGAL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                    color: const Color(0xFF8F8A8B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PRIVACY POLICY',
                  style: GoogleFonts.anton(
                    fontSize: 40,
                    height: 1.05,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 24),
                _buildLegalCard(
                  number: '01',
                  title: 'Information We Collect',
                  body: 'We collect information you provide directly, such as your name, email, profile picture, and content you post. We also collect usage data and device information.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '02',
                  title: 'How We Use Your Information',
                  body: 'We use your information to provide, maintain, and improve TRIBE. This includes personalizing your experience, communicating with you, and analyzing usage patterns.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '03',
                  title: 'Data Storage',
                  body: 'Your data is stored securely using Firebase (Google Cloud Platform). We implement appropriate security measures to protect your information.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '04',
                  title: 'Data Sharing',
                  body: 'We do not sell your personal information. We may share data with service providers who perform services on our behalf, such as Firebase.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '05',
                  title: 'Your Rights',
                  body: 'You have the right to access, update, or delete your personal information. You can delete your account at any time through the profile settings.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '06',
                  title: 'Changes to This Policy',
                  body: 'We may update this privacy policy from time to time. We will notify you of any material changes by posting the new policy on this page.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalCard({
    required String number,
    required String title,
    required String body,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0C0D),
        border: Border.all(color: const Color(0xFF2B2627), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8F8A8B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.anton(
                    fontSize: 28,
                    height: 1.07,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.46,
                    color: const Color(0xFFF4F1F0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
