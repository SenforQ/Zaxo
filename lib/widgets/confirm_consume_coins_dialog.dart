import 'package:flutter/material.dart';

const Color _themeColor = Color(0xFF260FA9);

/// Shows a dialog to confirm consuming [coins] for [featureName].
/// User must check "I agree" to not generate violent, pornographic, or other
/// content that violates the User Agreement.
/// Returns true if user confirmed with agreement checked, false otherwise.
Future<bool> showConfirmConsumeCoinsDialog({
  required BuildContext context,
  required int coins,
  required String featureName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ConfirmConsumeCoinsDialog(
      coins: coins,
      featureName: featureName,
      dialogContext: dialogContext,
    ),
  );
  return result == true;
}

class _ConfirmConsumeCoinsDialog extends StatefulWidget {
  final int coins;
  final String featureName;
  final BuildContext dialogContext;

  const _ConfirmConsumeCoinsDialog({
    required this.coins,
    required this.featureName,
    required this.dialogContext,
  });

  @override
  State<_ConfirmConsumeCoinsDialog> createState() => _ConfirmConsumeCoinsDialogState();
}

class _ConfirmConsumeCoinsDialogState extends State<_ConfirmConsumeCoinsDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Confirm & Agree',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will consume ${widget.coins} coins for ${widget.featureName}.',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You agree not to generate any violent, pornographic or other content that violates our User Agreement.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'I have read and agree to the User Agreement.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              title: const Text(
                'I agree',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              activeColor: _themeColor,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(widget.dialogContext).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: _agreed
              ? () => Navigator.of(widget.dialogContext).pop(true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _themeColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Confirm',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
