import 'package:flutter/material.dart';

class Live2DWebView extends StatelessWidget {
  final String assetPath;
  final double zoom;

  const Live2DWebView({
    super.key,
    required this.assetPath,
    this.zoom = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'Live2D WebView is not supported on this platform yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: scheme.onSurface),
      ),
    );
  }
}
