import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/iconfont/RcIcon.dart';

class SearchWidget extends StatefulWidget{
  @override
  State<SearchWidget> createState() => _SearchWidget();
}

class _SearchWidget extends State<SearchWidget>{
  @override
  Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(right: 15),
        child: IconButton(
            hoverColor: Colors.pink[100],
            focusColor: Colors.pink[100],
            highlightColor: Colors.pink[200],
            onPressed: () {
              Get.bottomSheet(Container(
                color: Colors.white,
                height: 400,
                child: Column(
                  children: [
                    const ListTile(
                      title:Text( "选择主题"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sunny),
                      onTap: () {
                        Get.changeTheme(ThemeData.light());
                        Get.back();
                      },
                      title: const Text(
                        "亮色",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.nightlight),
                      onTap: () {
                        Get.changeTheme(ThemeData.dark());
                        Get.back();
                      },
                      title: const Text(
                        "暗色",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const ListTile(
                      title:Text( "选择语言"),
                    ),
                    ListTile(
                      leading: const Icon(RcIcon.chinese),
                      onTap: () {
                        var locale = const Locale("zh",'CN');
                        Get.updateLocale(locale);
                        Get.back();
                      },
                      title: const Text(
                        "简体中文",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(RcIcon.english),
                      onTap: () {
                        var locale = const Locale("en",'US');
                        Get.updateLocale(locale);
                        Get.back();
                      },
                      title: const Text(
                        "English",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(RcIcon.japanese),
                      onTap: () {
                        var locale = const Locale("ja",'JP');
                        Get.updateLocale(locale);
                        Get.back();
                      },
                      title: const Text(
                        "日本語",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ));
            },
            icon: const Icon(Icons.widgets)),
      );
  }
}