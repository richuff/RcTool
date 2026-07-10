import 'package:flutter/material.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/live2d/live2d_webview.dart';
import 'package:rctool/widget/search_widget.dart';

import '../feature/design/icon_button_no_ripple.dart';
import '../widget/main_drawer.dart';

class LiveTod extends StatefulWidget {
  const LiveTod({super.key});

  @override
  State<LiveTod> createState() => _LiveTod();
}

class _LiveTod extends State<LiveTod> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: scaffoldKey,
      drawerScrimColor: Colors.transparent,
      drawer: MainDrawer(() {
        scaffoldKey.currentState?.closeDrawer();
      }),
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: Builder(builder: (context) {
          return Column(children: [
            const Padding(padding: EdgeInsets.only(top: 8)),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButtonNoRipple(
                hoverColor: scheme.primaryContainer,
                focusColor: scheme.primaryContainer,
                highlightColor: scheme.secondaryContainer,
                alignment: Alignment.bottomCenter,
                icon: const Icon(
                  Icons.menu,
                  size: 26,
                ),
                color: scheme.onSurface,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ]);
        }),
        actions: const [SearchWidget()],
      ),
      body: Container(
        decoration: BackGroundEnum.livetodBackGround.decoration,
        child: const Live2DWebView(
          assetPath: 'assets/live2d/viewer/index.html',
        ),
      ),
    );
  }
}
