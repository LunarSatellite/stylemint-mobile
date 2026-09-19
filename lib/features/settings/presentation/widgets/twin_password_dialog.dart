import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Kept in a separate widget file so the password fields can be independently
/// exercised without coupling encryption keys to application state.
class TwinPasswordDialog extends StatefulWidget {
  const TwinPasswordDialog({required this.confirmPassword, super.key});

  final bool confirmPassword;

  @override
  State<TwinPasswordDialog> createState() => _TwinPasswordDialogState();
}

class _TwinPasswordDialogState extends State<TwinPasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.length < 10) {
      setState(() => _error = 'Use at least 10 characters.');
      return;
    }
    if (widget.confirmPassword && _password.text != _confirmation.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.bgAppBody,
      title: Text(
        widget.confirmPassword ? 'Protect your backup' : 'Unlock your backup',
        style: const TextStyle(color: DesignTokens.textWhite),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.confirmPassword
                ? 'This password stays with you. StyleMint cannot recover it.'
                : 'Enter the password used when this backup was created.',
            style: const TextStyle(color: DesignTokens.textLight),
          ),
          const SizedBox(height: DesignTokens.s12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            autofocus: true,
            onSubmitted: (_) => widget.confirmPassword ? null : _submit(),
            style: const TextStyle(color: DesignTokens.textWhite),
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          if (widget.confirmPassword) ...[
            const SizedBox(height: DesignTokens.s8),
            TextField(
              controller: _confirmation,
              obscureText: _obscure,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmPassword ? 'Encrypt' : 'Unlock'),
        ),
      ],
    );
  }
}
