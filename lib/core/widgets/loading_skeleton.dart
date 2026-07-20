import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Loading skeleton widget for content loading states
class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  /// Card skeleton
  const LoadingSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius = 16,
  });

  /// Circle skeleton (avatar)
  const LoadingSkeleton.circle({
    super.key,
    this.width = 48,
    this.height = 48,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// List loading skeleton with multiple items
class ListLoadingSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListLoadingSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const LoadingSkeleton.circle(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 14,
                    ),
                    const SizedBox(height: 8),
                    LoadingSkeleton(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dashboard card loading skeleton
class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: List.generate(
              3,
              (_) => const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: LoadingSkeleton(height: 100, borderRadius: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              3,
              (_) => const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: LoadingSkeleton(height: 100, borderRadius: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Chart
          const LoadingSkeleton(height: 220, borderRadius: 16),
          const SizedBox(height: 24),
          // Activity items
          ...List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LoadingSkeleton(height: 72, borderRadius: 12),
            ),
          ),
        ],
      ),
    );
  }
}
