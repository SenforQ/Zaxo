import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_ui.dart';
import '../services/prefs_service.dart';
import '../widgets/gradient_bubbles_background.dart';
import 'about_screen.dart';
import 'editor_screen.dart';
import 'feedback_screen.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';
import 'wallet_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onSwitchToTab});

  final void Function(int index)? onSwitchToTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  String? _avatarPath;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await PrefsService.shared.getUserName();
    final coins = await PrefsService.shared.getUserCoins();
    final relPath = await PrefsService.shared.getUserAvatarPath();
    String? absPath;
    if (relPath != null && relPath.isNotEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$relPath');
      if (f.existsSync()) absPath = f.path;
    }
    if (mounted) {
      setState(() {
        _userName = name;
        _coins = coins;
        _avatarPath = absPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBubblesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text('Profile', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: floatingTabBarBottomInset(context),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditorScreen()),
                    );
                    _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.transparent,
                          backgroundImage: _avatarPath != null
                              ? FileImage(File(_avatarPath!))
                              : const AssetImage('assets/userdefault.png') as ImageProvider,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _userName ?? 'Zaxo',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WalletPage()),
                      ).then((_) => _load());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          const Text('Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('$_coins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _Section(
                  title: 'Me',
                  items: [
                    _SectionItem(icon: Icons.folder, title: 'My Works', onTap: () {
                      widget.onSwitchToTab?.call(2);
                    }),
                  ],
                ),
                _Section(
                  title: 'Support',
                  items: [
                    _SectionItem(icon: Icons.star, title: 'Rate App', onTap: _rateApp),
                    _SectionItem(icon: Icons.share, title: 'Share App', onTap: _shareApp),
                    _SectionItem(icon: Icons.mail, title: 'Feedback', onTap: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                      );
                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submitted successfully')),
                        );
                      }
                    }),
                  ],
                ),
                _Section(
                  title: 'Settings',
                  items: [
                    _SectionItem(icon: Icons.edit, title: 'Edit information', onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditorScreen()),
                      );
                      _load();
                    }),
                  ],
                ),
                _Section(
                  title: 'Legal',
                  items: [
                    _SectionItem(icon: Icons.privacy_tip, title: 'Privacy Policy', onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                      );
                    }),
                    _SectionItem(icon: Icons.description, title: 'User Agreement', onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UserAgreementPage()),
                      );
                    }),
                  ],
                ),
                _Section(
                  title: 'About',
                  items: [
                    _SectionItem(icon: Icons.info, title: 'About Us', onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rateApp() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating is not available')),
      );
    }
  }

  void _shareApp() {
    SharePlus.instance.share(ShareParams(text: 'Check out Zaxo! https://apps.apple.com/app/zaxo'));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_SectionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: items.asMap().entries.map((e) {
              return Material(
                color: Colors.white.withValues(alpha: 0.25),
                child: InkWell(
                  onTap: e.value.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(e.value.icon, size: 22, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          e.value.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.white54, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SectionItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _SectionItem({required this.icon, required this.title, required this.onTap});
}
