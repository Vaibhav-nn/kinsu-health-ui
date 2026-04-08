import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Shared iOS-style back button used across detail screens.
class IosBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final IconData icon;

  const IosBackButton({
    super.key,
    this.onTap,
    this.size = 42,
    this.iconSize = 20,
    this.icon = Icons.arrow_back_ios_new_rounded,
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F4F5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _handleTap(context),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: KinsuTheme.primaryDark, size: iconSize),
        ),
      ),
    );
  }
}
