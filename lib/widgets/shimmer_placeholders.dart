/// Reusable shimmer loading placeholders for key screens.
///
/// Usage:
///   if (isLoading) const ShimmerCardList() else ActualContent()
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme.dart';

// ── Base shimmer box ──────────────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Shimmer wrapper ───────────────────────────────────────────────────────────

class KinsuShimmer extends StatelessWidget {
  final Widget child;

  const KinsuShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8ECED),
      highlightColor: const Color(0xFFF4F7F7),
      child: child,
    );
  }
}

// ── Card-shaped placeholder ───────────────────────────────────────────────────

class ShimmerCard extends StatelessWidget {
  final double height;
  final EdgeInsets? margin;

  const ShimmerCard({super.key, this.height = 90, this.margin});

  @override
  Widget build(BuildContext context) {
    return KinsuShimmer(
      child: Container(
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KinsuTheme.radiusLG),
        ),
      ),
    );
  }
}

// ── Stacked list of card placeholders ────────────────────────────────────────

class ShimmerCardList extends StatelessWidget {
  final int count;
  final double cardHeight;
  final double spacing;
  final EdgeInsets padding;

  const ShimmerCardList({
    super.key,
    this.count = 4,
    this.cardHeight = 88,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(count, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? spacing : 0),
            child: ShimmerCard(height: cardHeight),
          );
        }),
      ),
    );
  }
}

// ── Medication-style row placeholder ─────────────────────────────────────────

class ShimmerMedicationRow extends StatelessWidget {
  const ShimmerMedicationRow({super.key});

  @override
  Widget build(BuildContext context) {
    return KinsuShimmer(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KinsuTheme.radiusLG),
        ),
        child: Row(
          children: [
            const _ShimmerBox(width: 44, height: 44, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: double.infinity * 0.7, height: 14),
                  const SizedBox(height: 8),
                  const _ShimmerBox(width: 100, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _ShimmerBox(width: 60, height: 28, radius: 14),
          ],
        ),
      ),
    );
  }
}

class ShimmerMedicationList extends StatelessWidget {
  final int count;

  const ShimmerMedicationList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(count, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? 12 : 0),
            child: const ShimmerMedicationRow(),
          );
        }),
      ),
    );
  }
}

// ── Vital tile placeholder ────────────────────────────────────────────────────

class ShimmerVitalTile extends StatelessWidget {
  const ShimmerVitalTile({super.key});

  @override
  Widget build(BuildContext context) {
    return KinsuShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KinsuTheme.radiusLG),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ShimmerBox(width: 80, height: 11),
            const SizedBox(height: 10),
            const _ShimmerBox(width: 120, height: 28, radius: 6),
            const SizedBox(height: 8),
            _ShimmerBox(width: double.infinity, height: 10),
          ],
        ),
      ),
    );
  }
}

class ShimmerVitalGrid extends StatelessWidget {
  const ShimmerVitalGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(child: ShimmerVitalTile()),
              SizedBox(width: 12),
              Expanded(child: ShimmerVitalTile()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: ShimmerVitalTile()),
              SizedBox(width: 12),
              Expanded(child: ShimmerVitalTile()),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Profile placeholder ───────────────────────────────────────────────────────

class ShimmerProfileHeader extends StatelessWidget {
  const ShimmerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return KinsuShimmer(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const _ShimmerBox(width: 68, height: 68, radius: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: double.infinity * 0.6, height: 18),
                  const SizedBox(height: 10),
                  const _ShimmerBox(width: 140, height: 13),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Family dashboard card placeholder ────────────────────────────────────────

class ShimmerFamilyCard extends StatelessWidget {
  const ShimmerFamilyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return KinsuShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KinsuTheme.radiusLG),
        ),
        child: Row(
          children: [
            const _ShimmerBox(width: 48, height: 48, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ShimmerBox(width: 120, height: 14),
                  const SizedBox(height: 8),
                  const _ShimmerBox(width: 80, height: 11),
                ],
              ),
            ),
            const _ShimmerBox(width: 40, height: 20, radius: 10),
          ],
        ),
      ),
    );
  }
}
