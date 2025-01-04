import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

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
                height: 200,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.sunny),
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
                      leading: Icon(Icons.nightlight),
                      onTap: () {
                        Get.changeTheme(ThemeData.dark());
                        Get.back();
                      },
                      title: const Text(
                        "暗色",
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  ],
                ),
              ));
            },
            icon: const Icon(Icons.widgets)),
      );
  }
}