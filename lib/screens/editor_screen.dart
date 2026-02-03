import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_ui.dart';
import '../services/prefs_service.dart';
import '../widgets/gradient_bubbles_background.dart';

const String _avatarFileName = 'user_avatar.jpg';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  String? _avatarRelativePath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await PrefsService.shared.getUserName();
    final signature = await PrefsService.shared.getUserSignature();
    final avatarPath = await PrefsService.shared.getUserAvatarPath();
    if (mounted) {
      setState(() {
        _nameController.text = name ?? '';
        _signatureController.text = signature ?? '';
        _avatarRelativePath = avatarPath;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSaveAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (xFile == null || !mounted) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_avatarFileName');
    final bytes = await xFile.readAsBytes();
    await file.writeAsBytes(bytes);
    if (mounted) {
      setState(() => _avatarRelativePath = _avatarFileName);
    }
  }

  Future<String?> _getAvatarAbsolutePath() async {
    if (_avatarRelativePath == null || _avatarRelativePath!.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final fullPath = '${dir.path}/$_avatarRelativePath';
    final f = File(fullPath);
    return f.existsSync() ? fullPath : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Edit information', style: TextStyle(color: Colors.white)),
      ),
      body: GradientBubblesBackground(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: floatingTabBarBottomInset(context),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickAndSaveAvatar,
                  child: Center(
                    child: FutureBuilder<String?>(
                      future: _getAvatarAbsolutePath(),
                      builder: (context, snapshot) {
                        final path = snapshot.data;
                        if (path != null) {
                          return CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.transparent,
                            backgroundImage: FileImage(File(path)),
                          );
                        }
                        return CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.transparent,
                          backgroundImage: const AssetImage('assets/userdefault.png'),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to change avatar',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Nickname',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter nickname',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Signature',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _signatureController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter signature',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                FilledButton(
                  onPressed: () async {
                    final name = _nameController.text.trim().isEmpty ? 'Zaxo' : _nameController.text.trim();
                    final signature = _signatureController.text.trim();
                    await PrefsService.shared.setUserName(name);
                    await PrefsService.shared.setUserSignature(signature.isEmpty ? null : signature);
                    await PrefsService.shared.setUserAvatarPath(_avatarRelativePath);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Save'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
