import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                  'TERMS OF SERVICE',
                  style: GoogleFonts.anton(
                    fontSize: 40,
                    height: 1.05,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 24),
                _buildLegalCard(
                  number: '01',
                  title: 'Acceptance of Terms',
                  body: 'By using TRIBE, you agree to these terms. If you do not agree, please do not use our service.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '02',
                  title: 'User Conduct',
                  body: 'You agree to use TRIBE for lawful purposes only. You must not post content that is illegal, harmful, threatening, abusive, or otherwise objectionable.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '03',
                  title: 'Content Ownership',
                  body: 'You retain ownership of content you post to TRIBE. By posting, you grant us a license to use, display, and distribute your content on our platform.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '04',
                  title: 'Account Security',
                  body: 'You are responsible for maintaining the confidentiality of your account credentials. Notify us immediately of any unauthorized use.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '05',
                  title: 'Termination',
                  body: 'We reserve the right to suspend or terminate your account at any time for violation of these terms.',
                ),
                const SizedBox(height: 16),
                _buildLegalCard(
                  number: '06',
                  title: 'Changes to Terms',
                  body: 'We may update these terms from time to time. Continued use of TRIBE after changes constitutes acceptance of the new terms.',
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
