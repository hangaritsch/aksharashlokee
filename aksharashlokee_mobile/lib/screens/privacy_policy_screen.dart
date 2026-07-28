import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'aksharashlokee@gmail.com',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF9FAFB),
              const Color(0xFFE8F4FD),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    CupertinoIcons.back,
                    color: Color(0xFF007AFF),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      const Color(0xFF007AFF),
                      const Color(0xFF5856D6),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                centerTitle: true,
                floating: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildOverviewCard(),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Information We Collect',
                        icon: CupertinoIcons.person_crop_circle,
                        color: const Color(0xFF007AFF),
                        body:
                            'We collect the information you provide directly when you create an account, sign in, verify your email, or contact us. This may include your name, email address, password, OTP verification data, and basic profile details stored by our app or backend service.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'How We Use Information',
                        icon: CupertinoIcons.checkmark_shield,
                        color: const Color(0xFF34C759),
                        body:
                            'We use your information to create and manage your account, authenticate sign-in requests, verify your email address, deliver app functionality, and respond to support or volunteer inquiries. The app also stores your signed-in state so you can access the app more easily.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Storage and Security',
                        icon: CupertinoIcons.lock_shield,
                        color: const Color(0xFF5856D6),
                        body:
                            'Authentication tokens are stored securely on your device using protected storage. Basic user profile details may be saved locally so the app can remember your signed-in state. We take reasonable steps to protect this data, but no method of storage or transmission is completely secure.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Sharing and Third Parties',
                        icon: CupertinoIcons.share,
                        color: const Color(0xFFFF9500),
                        body:
                            'We do not sell your personal information. We may share data with our application backend and other service providers only as needed to operate the app, verify accounts, or deliver requested features. If you choose to email us, your message is handled by your email provider under its own policy.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Your Choices',
                        icon: CupertinoIcons.gear,
                        color: const Color(0xFF007AFF),
                        body:
                            'You can stop using the app, log out, or contact us if you want assistance with your account data. If you need us to review, correct, or delete information associated with your account, email us and we will respond as soon as reasonably possible.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Children\'s Privacy',
                        icon: CupertinoIcons.person_2,
                        color: const Color(0xFF34C759),
                        body:
                            'The app is intended for general educational use and is not knowingly directed to children under 13 without appropriate supervision. If you believe a child has provided personal information to us, contact us and we will work to address the issue.',
                      ),
                      const SizedBox(height: 16),
                      _buildContactCard(),
                      const SizedBox(height: 24),
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

  Widget _buildOverviewCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF007AFF).withValues(alpha: 0.1),
            const Color(0xFF5856D6).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF007AFF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.shield_lefthalf_fill,
            size: 44,
            color: Color(0xFF007AFF),
          ),
          const SizedBox(height: 12),
          const Text(
            'We respect your privacy and keep this policy focused on what the app actually collects and stores.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4B5563),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Last updated: July 28, 2026',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String body,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.65,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF9500).withValues(alpha: 0.1),
            const Color(0xFFFFD60A).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF9500).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Contact for Privacy Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF9500),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'If you have questions about this policy or want help with your account data, email us and we will respond directly.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4B5563),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _launchEmail,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.mail_solid,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'aksharashlokee@gmail.com',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
