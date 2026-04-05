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
    _ShellNavItem('Home', Icons.home_outlined, Icons.home_rounded),
    _ShellNavItem('Vault', Icons.folder_outlined, Icons.folder_rounded),
    _ShellNavItem('Track', Icons.show_chart_rounded, Icons.show_chart_rounded),
    _ShellNavItem('Family', Icons.people_outline_rounded, Icons.people_rounded),
    _ShellNavItem(
        'AI', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 14,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: KinsuTheme.divider)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x100F172A),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final selected = index == currentIndex;
                    final color = selected
                        ? KinsuTheme.primary
                        : KinsuTheme.textSecondary;

                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onTap(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? KinsuTheme.primaryLight
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  selected ? item.activeIcon : item.icon,
                                  color: color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          Positioned(
            top: -14,
            child: GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: KinsuTheme.primaryDark,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: KinsuTheme.primaryDark.withValues(alpha: 0.26),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
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
