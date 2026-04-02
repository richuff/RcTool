import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/search_widget.dart';

import '../feature/design/icon_button_no_ripple.dart';
import '../widget/main_drawer.dart';

class AboutAuthor extends StatefulWidget {
  const AboutAuthor({super.key});

  @override
  State<AboutAuthor> createState() => _AboutAuthor();
}

class _AboutAuthor extends State<AboutAuthor> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        drawerScrimColor: Colors.transparent,
        drawer: MainDrawer((){
          scaffoldKey.currentState?.closeDrawer();
        }),
        appBar: AppBar(
            backgroundColor: Colors.pink[50],
            leading: Builder(builder: (context) {
              return Column(children: [
                const Padding(padding: EdgeInsets.only(top: 8)),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: IconButtonNoRipple(
                    hoverColor: Colors.pink[100],
                    focusColor: Colors.pink[100],
                    highlightColor: Colors.pink[200],
                    alignment: Alignment.bottomCenter,
                    icon: const Icon(
                      Icons.menu,
                      size: 26,
                    ),
                    color: Colors.black,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              ]);
            }),
            actions: const [
              SearchWidget()
            ]),
        body: Container(
          decoration: BackGroundEnum.aboutBackGround.decoration,
          child: ListView(
            children:[
              Text(
                "${"关于作者".tr} or ${"作者的话".tr}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.pink[400],
                  fontSize: 25,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                title: Text("关于作者".tr, style: const TextStyle(color: Colors.black,fontSize: 18)),
                subtitle: Text(
                  "一".tr,
                  style: const TextStyle(color: Colors.black,fontSize: 14),
                ),
                leading: ClipOval(
                  child: Image.network(
                    "https://p1.meituan.net/csc/949ad40707d4b4bab7e2ebafbd649aa8211830.jpg",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                title: Text(
                  "作者的话".tr,
                  style: const TextStyle(color: Colors.black,fontSize: 18),
                ),
                subtitle: Text(
                  "二".tr,
                  style: const TextStyle(color: Colors.black,fontSize: 14),
                ),
                leading: ClipOval(
                  child: Image.network(
                    "https://p1.meituan.net/csc/949ad40707d4b4bab7e2ebafbd649aa8211830.jpg",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            ],
          )
        ));
  }
}
