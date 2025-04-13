import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../feature/design/IconButtonNoRipple.dart';
import '../../widget/BackGround/MusicBackGround.dart';
import '../../widget/MainDrawer.dart';
import '../../widget/SearchWidget.dart';

class Ranking extends StatefulWidget{
  const Ranking({super.key});
  
  @override
  State<Ranking> createState() => _Ranking();
  
}

class _Ranking extends State<Ranking> {
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
          actions: const [SearchWidget()]),
      body: Container(
          width: double.infinity,
          decoration: musicBackGround(),
          child: Column(children: [
            Flexible(
                child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false, dragDevices: {
                      //必须设置此事件，不然无法滚动
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    }),
                    child: Text("data")
                )),
          ])),
    );
  }
}