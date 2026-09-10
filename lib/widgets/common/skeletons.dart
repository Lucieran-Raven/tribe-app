import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width, height, radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2E),
      highlightColor: const Color(0xFF3A3A40),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const ShimmerBox(width: 40, height: 40, radius: 20),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const ShimmerBox(width: 120, height: 12),
                const SizedBox(height: 6),
                const ShimmerBox(width: 80, height: 10),
              ]),
            ]),
            const SizedBox(height: 16),
            const ShimmerBox(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const ShimmerBox(width: 250, height: 14),
            const SizedBox(height: 16),
            const ShimmerBox(width: double.infinity, height: 160, radius: 16),
            const SizedBox(height: 12),
            Row(children: [
              const ShimmerBox(width: 60, height: 24, radius: 12),
              const SizedBox(width: 16),
              const ShimmerBox(width: 60, height: 24, radius: 12),
            ]),
          ],
        ),
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const ShimmerBox(width: 78, height: 78, radius: 39),
            const SizedBox(width: 18),
            Expanded(child: Row(children: [
              Expanded(child: Column(children: [
                const ShimmerBox(width: 30, height: 17),
                const SizedBox(height: 2),
                const ShimmerBox(width: 40, height: 11),
              ])),
              Expanded(child: Column(children: [
                const ShimmerBox(width: 30, height: 17),
                const SizedBox(height: 2),
                const ShimmerBox(width: 40, height: 11),
              ])),
              Expanded(child: Column(children: [
                const ShimmerBox(width: 30, height: 17),
                const SizedBox(height: 2),
                const ShimmerBox(width: 40, height: 11),
              ])),
            ])),
          ]),
          const SizedBox(height: 14),
          const ShimmerBox(width: 150, height: 15),
          const SizedBox(height: 1),
          const ShimmerBox(width: 100, height: 12),
          const SizedBox(height: 6),
          const ShimmerBox(width: 120, height: 12),
          const SizedBox(height: 6),
          const ShimmerBox(width: 200, height: 13),
        ],
      ),
    );
  }
}
