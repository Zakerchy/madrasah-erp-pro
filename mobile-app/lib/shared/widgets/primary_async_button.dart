import 'package:flutter/material.dart';

/// Submit button that automatically manages loading state and prevents double-taps
/// while an async operation is running.
class PrimaryAsyncButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Future<void> Function()? onPressed;
  final bool expand;

  const PrimaryAsyncButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  @override
  State<PrimaryAsyncButton> createState() => _PrimaryAsyncButtonState();
}

class _PrimaryAsyncButtonState extends State<PrimaryAsyncButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : (widget.icon != null
            ? Icon(widget.icon, size: 18)
            : const SizedBox.shrink());

    final button = widget.icon != null || _busy
        ? FilledButton.icon(
            onPressed: widget.onPressed == null || _busy ? null : _handleTap,
            icon: child,
            label: Text(widget.label),
          )
        : FilledButton(
            onPressed: widget.onPressed == null || _busy ? null : _handleTap,
            child: Text(widget.label),
          );

    return widget.expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
