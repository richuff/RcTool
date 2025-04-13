import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/IsDarkController.dart';
import 'package:rctool/iconfont/RcIcon.dart';

import '../feature/design/IconButtonNoRipple.dart';
import 'TextWidget/DarkLightText.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchWidget();
}

class _SearchWidget extends State<SearchWidget> {
  IsDarkController isDarkController = Get.put(IsDarkController());
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: IconButtonNoRipple(
          hoverColor: Colors.pink[100],
          focusColor: Colors.pink[100],
          highlightColor: Colors.pink[200],
          onPressed: () {
            Get.bottomSheet(Container(
              decoration: BoxDecoration(
                  color: Get.isDarkMode ? Colors.black : Colors.white,
                  image: const DecorationImage(
                      opacity: 0.2,
                      image: AssetImage("image/BottomBackGround.jpg"),
                      fit: BoxFit.cover)),
              height: height > 400 ? 400 : 200,
              child: ListView(
                children: [
                  ExpansionTile(
                    title: const Text("选择主题"),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.sunny),
                        onTap: () {
                          Get.changeTheme(ThemeData.light());
                          isDarkController.updateIsDark(false);
                          Get.back();
                        },
                        title: darkLightText("亮色")
                      ),
                      ListTile(
                        leading: const Icon(Icons.nightlight),
                        onTap: () {
                          Get.changeTheme(ThemeData.dark());
                          isDarkController.updateIsDark(true);
                          Get.back();
                        },
                        title: darkLightText("暗色"),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text("选择语言"),
                    children: [
                      ListTile(
                        leading: const Icon(RcIcon.chinese),
                        onTap: () {
                          var locale = const Locale("zh", 'CN');
                          Get.updateLocale(locale);
                          Get.back();
                        },
                        title: darkLightText("简体中文")
                      ),
                      ListTile(
                        leading: const Icon(RcIcon.english),
                        onTap: () {
                          var locale = const Locale("en", 'US');
                          Get.updateLocale(locale);
                          Get.back();
                        },
                        title: darkLightText("English")
                      ),
                      ListTile(
                        leading: const Icon(RcIcon.japanese),
                        onTap: () {
                          var locale = const Locale("ja", 'JP');
                          Get.updateLocale(locale);
                          Get.back();
                        },
                        title: darkLightText("日本語")
                      ),
                    ],
                  )
                ],
              ),
            ));
          },
          icon: const Icon(Icons.widgets)),
    );
  }
}
