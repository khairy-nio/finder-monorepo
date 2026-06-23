import 'package:flutter/material.dart';
import '../../core/constants/finder_colors.dart';
import '../../core/utils/app_messenger.dart';

/// Privacy Policy & Terms of Use Screen
class PrivacyPolicyScreen extends StatefulWidget {
  final bool isFromOnboarding;

  const PrivacyPolicyScreen({
    super.key,
    this.isFromOnboarding = false,
  });

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _hasAccepted = false;

  final List<Map<String, dynamic>> _sections = [
    {
      'title': '1. Data We Collect',
      'icon': Icons.data_usage_outlined,
      'content': 'We collect the following personal information to provide our services:\n'
          '• Full Name & Phone Number\n'
          '• Email Address\n'
          '• National ID Number\n'
          '• ID Images (Front and Back)\n'
          '• Personal Selfie Photo\n'
          '• Location Data (if enabled for matched results)',
    },
    {
      'title': '2. How We Use Your Data',
      'icon': Icons.settings_suggest_outlined,
      'content': 'Your data is strictly used for the following purposes:\n'
          '• Identity Verification (KYC) to maintain platform safety\n'
          '• Fraud prevention and security monitoring\n'
          '• Improving user experience and matching accuracy\n'
          '• Enabling secure communication between verified users',
    },
    {
      'title': '3. Data Storage & Security',
      'icon': Icons.security_outlined,
      'content': 'We employ bank-grade security to protect your data:\n'
          '• All personal data is encrypted at rest and in transit (HTTPS)\n'
          '• ID images and selfies are securely stored on protected servers\n'
          '• There is NO public access to your sensitive personal data',
    },
    {
      'title': '4. Data Sharing',
      'icon': Icons.share_outlined,
      'content': 'We respect your privacy:\n'
          '• Your data is NEVER sold to third parties\n'
          '• Data may only be shared with law enforcement or regulatory bodies for legal or strict security reasons',
    },
    {
      'title': '5. User Rights',
      'icon': Icons.gavel_outlined,
      'content': 'You have full control over your data:\n'
          '• Right to access the personal data we hold about you\n'
          '• Right to update or correct inaccurate information\n'
          '• Right to permanently delete your account and associated data',
    },
    {
      'title': '6. Verification Disclaimer',
      'icon': Icons.warning_amber_outlined,
      'content': 'Platform Integrity:\n'
          '• Users must provide real, accurate, and up-to-date data\n'
          '• Providing fake or forged information will result in immediate and permanent account suspension',
    },
    {
      'title': '7. Retention Policy',
      'icon': Icons.hourglass_bottom_outlined,
      'content': 'Data Minimization:\n'
          '• Your data is stored only as long as necessary to fulfill the purposes outlined in this policy or as required by law',
    },
    {
      'title': '8. Contact Us',
      'icon': Icons.contact_support_outlined,
      'content': 'For any privacy-related questions or data requests:\n'
          'Email our support team at: privacy@finderapp.com',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: FinderColors.primaryBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Privacy & Terms',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for the back button
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Intro Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FinderColors.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: FinderColors.primaryBlue.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: FinderColors.primaryBlue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Last Updated: October 2023',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: FinderColors.primaryBlue.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'We value your privacy and are committed to protecting your personal data. Please read these terms carefully before proceeding with identity verification.',
                              style: TextStyle(
                                fontSize: 15,
                                color: FinderColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      const Text(
                        'POLICY DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Expandable Sections
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sections.length,
                        itemBuilder: (context, index) {
                          final section = _sections[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: ExpansionTile(
                              collapsedIconColor: FinderColors.primaryBlue,
                              iconColor: FinderColors.primaryBlue,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: FinderColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  section['icon'] as IconData,
                                  color: FinderColors.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                section['title'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: FinderColors.primaryBlue,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  child: Text(
                                    section['content'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Fixed Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _hasAccepted,
                          activeColor: FinderColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasAccepted = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'I have read and agree to the Privacy Policy and Terms of Use',
                          style: TextStyle(
                            fontSize: 14,
                            color: FinderColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hasAccepted
                          ? () {
                              if (widget.isFromOnboarding) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/kyc-verification',
                                );
                              } else {
                                AppMessenger.showSuccess('Preferences saved.');
                                Navigator.pop(context);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FinderColors.primaryBlue,
                        disabledBackgroundColor:
                            FinderColors.primaryBlue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isFromOnboarding ? 'I Agree & Continue' : 'Save & Close',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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
