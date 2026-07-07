import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/routers/route_path.dart';

class RightToolbar extends StatelessWidget {
  const RightToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: _MiniFeatureCard(
            title: "排行榜".tr,
            image: "image/Reward.png",
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            onTap: () => Get.toNamed(RoutePath.RANKING),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _MiniFeatureCard(
            title: "歌单".tr,
            image: "image/Expect.png",
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            onTap: () => Get.toNamed(RoutePath.ALBUM),
          ),
        ),
      ],
    );
  }
}

class _MiniFeatureCard extends StatelessWidget {
  final String title;
  final String image;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _MiniFeatureCard({
    required this.title,
    required this.image,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outline.withOpacity(0.18)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -3,
                bottom: -2,
                child: Opacity(
                  opacity: 0.82,
                  child: Image.asset(
                    image,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
