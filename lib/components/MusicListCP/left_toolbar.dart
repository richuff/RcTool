import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routers/route_path.dart';

class LeftToolbar extends StatelessWidget {
  const LeftToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _HomeFeatureCard(
            title: "每日推荐".tr,
            subtitle: "Daily Mix",
            image: "image/Mika.gif",
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            onTap: () => Get.toNamed(RoutePath.RECOMMEND),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _HomeFeatureCard(
            title: "我的喜欢".tr,
            subtitle: "Favorite",
            image: "image/ARoNa.png",
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            onTap: () => Get.toNamed(RoutePath.MUSICLIKE),
          ),
        ),
      ],
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _HomeFeatureCard({
    required this.title,
    required this.subtitle,
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
          height: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outline.withOpacity(0.18)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -4,
                child: Opacity(
                  opacity: 0.86,
                  child: Image.asset(
                    image,
                    width: 92,
                    height: 92,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned.fill(
                right: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: foregroundColor.withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
