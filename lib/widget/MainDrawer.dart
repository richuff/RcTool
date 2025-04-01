import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/widget/Settingdialog.dart';

import '../iconfont/RcIcon.dart';
import '../routers/RoutePath.dart';

class MainDrawer extends StatelessWidget {
  
  final closeDrawer;

  MainDrawer(this.closeDrawer);
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Drawer(
      width: 250,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Image.asset("image/RcTool.png"),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text('主页'.tr),
            onTap: () {
              Get.toNamed(RoutePath.HOME);
            },
          ),
          const Divider(
            height: 2,
          ),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: Text('听音乐'.tr),
            onTap: () {
              closeDrawer();
              Get.toNamed(RoutePath.MUSIC);
            },
          ),
          ListTile(
            leading: const Icon(RcIcon.livetod),
            title: const Text('Live2d'),
            onTap: () {
              closeDrawer();
              Get.toNamed(RoutePath.LIVETOD);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_box_rounded),
            title: Text('关于作者'.tr),
            onTap: () {
              closeDrawer();
              Get.toNamed(RoutePath.ABOUT);
            },
          ),
          const Divider(
            height: 2,
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text('设置'.tr),
            onTap: () {
              closeDrawer();
              //Get.toNamed(RoutePath.ABOUT);
              showDialog(context: context, builder:(context){
                return Settingdialog();
              });
            },
          ),
        ],
      ),
    ));
  }
}
