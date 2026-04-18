import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Left-side navigation rail for Flutter Web desktop layout (≥ 900 px wide).
///
/// At 900–1199 px (narrow desktop) the rail collapses to icon-only (72 px).
/// At ≥ 1200 px it expands to show labels alongside icons (220 px).
class AppShellWebNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddTap;

  const AppShellWebNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAddTap,
  });

  static const _items = <_WebNavItem>[
    _WebNavItem('Home', Icons.home_outlined, Icons.home_rounded),
    _WebNavItem('Track', Icons.insights_outlined, Icons.insights_rounded),
    _WebNavItem('Vault', Icons.folder_outlined, Icons.folder_rounded),
    _WebNavItem('Family', Icons.people_outlined, Icons.people_rounded),
    _WebNavItem('AI', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isExpanded = width >= 1200;
    final navWidth = isExpanded ? 220.0 : 72.0;

    return Container(
      width: navWidth,
      decoration: const BoxDecoration(
        color: KinsuTheme.surface,
        border: Border(right: BorderSide(color: KinsuTheme.divider)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrand(isExpanded),
            const SizedBox(height: 8),
            _buildQuickAdd(isExpanded),
            const SizedBox(height: 8),
            const Divider(height: 1, color: KinsuTheme.divider),
            const SizedBox(height: 8),
            ...List.generate(
              _items.length,
              (i) => _buildNavItem(i, isExpanded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand(bool isExpanded) {
    final logo = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: KinsuTheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'K',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(isExpanded ? 16 : 18, 20, 16, 4),
      child: isExpanded
          ? Row(
              children: [
                logo,
                const SizedBox(width: 10),
                const Text(
                  'Kinsu Health',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: KinsuTheme.textPrimary,
                  ),
                ),
              ],
            )
          : logo,
    );
  }

  Widget _buildQuickAdd(bool isExpanded) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 12 : 14,
        vertical: 4,
      ),
      child: isExpanded
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Quick Add'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 42),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : Center(
              child: IconButton.filled(
                onPressed: onAddTap,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: KinsuTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(int index, bool isExpanded) {
    final item = _items[index];
    final selected = index == currentIndex;
    final iconColor =
        selected ? KinsuTheme.primaryDark : KinsuTheme.textSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 10 : 10,
        vertical: 2,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 12 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? KinsuTheme.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isExpanded
              ? Row(
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      color: iconColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? KinsuTheme.primaryDark
                            : KinsuTheme.textPrimary,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
        ),
      ),
    );
  }
}

class _WebNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _WebNavItem(this.label, this.icon, this.activeIcon);
}
