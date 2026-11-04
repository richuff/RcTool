import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rctool/widget/page_enter.dart';
import 'package:rctool/widget/slide_fade_in.dart';

Widget _home() => Scaffold(
      body: PageEnter(
        child: Column(
          children: stagger([
            const Text('a'),
            const Text('b'),
          ]),
        ),
      ),
    );

void main() {
  testWidgets('pop 回栈底页面不会重放入场动画', (tester) async {
    Get.testMode = true;
    await tester.pumpWidget(GetMaterialApp(
      home: _home(),
      getPages: [
        GetPage(name: '/b', page: () => const Scaffold(body: Text('b'))),
      ],
    ));
    await tester.pumpAndSettle();

    double homeOpacity() => tester
        .widget<FadeTransition>(
          find
              .descendant(
                of: find.byType(PageEnter),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    expect(homeOpacity(), 1);

    Get.toNamed('/b');
    await tester.pumpAndSettle();
    Get.until((route) => route.isFirst);
    await tester.pump();
    // 回到栈底页面时不应把入场动画重播一遍（否则会和页面切换动画叠在一起）
    expect(homeOpacity(), 1);
    await tester.pumpAndSettle();
    expect(homeOpacity(), 1);
  });
}
