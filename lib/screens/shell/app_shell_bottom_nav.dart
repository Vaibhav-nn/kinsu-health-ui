import 'package:flutter/material.dart';

import '../../core/theme.dart';

class AppShellBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddTap;

  const AppShellBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAddTap,
  });

  static const _items = <_ShellNavItem>[
    _ShellNavItem('HOME', Icons.home_outlined, Icons.home_rounded),
    _ShellNavItem(
      'TRACK',
      Icons.insights_outlined,
      Icons.insights_rounded,
    ),
    _ShellNavItem(
      'VAULT',
      Icons.folder_outlined,
      Icons.folder_rounded,
    ),
    _ShellNavItem(
      'AI',
      Icons.auto_awesome_outlined,
      Icons.auto_awesome_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalHeight = 88.0 + bottomInset;
    return SizedBox(
      height: totalHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 10,
            child: Container(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: KinsuTheme.divider)),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildItem(context, 0)),
                  Expanded(child: _buildItem(context, 1)),
                  const SizedBox(width: 78),
                  Expanded(child: _buildItem(context, 2)),
                  Expanded(child: _buildItem(context, 3)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 6,
            child: GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: KinsuTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    final selected = index == currentIndex;
    final isTrack = item.label == 'TRACK';
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final compactTrack = isTrack && selected && isAndroid;
    final color = isTrack
        ? const Color(0xFF91A0B4)
        : selected
            ? KinsuTheme.primaryDark
            : const Color(0xFF91A0B4);
    final isVault = item.label == 'VAULT';
    final iconData = selected ? item.activeIcon : item.icon;

    final iconWidget = isVault
        ? SizedBox(
            width: 32,
            height: 30,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Icon(iconData, color: color, size: 28),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: color,
                    size: 12,
                  ),
                ),
              ],
            ),
          )
        : Icon(
            iconData,
            color: color,
            size: compactTrack ? 26 : 28,
          );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap(index),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compactTrack ? 4 : 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            SizedBox(height: compactTrack ? 3 : 5),
            Text(
              item.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: isTrack ? (compactTrack ? 9.5 : 10) : 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: isTrack ? (compactTrack ? 1.5 : 1.8) : 1.2,
              ),
            ),
            if (isTrack && selected) ...[
              SizedBox(height: compactTrack ? 1 : 2),
              Container(
                width: compactTrack ? 38 : 42,
                height: compactTrack ? 2 : 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShellNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _ShellNavItem(this.label, this.icon, this.activeIcon);
}
