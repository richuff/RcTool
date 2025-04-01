import 'package:flutter/material.dart';
import 'package:rctool/widget/SearchWidget.dart';

import '../widget/BackGround/LivetodBackGround.dart';
import '../widget/MainDrawer.dart';

class LiveTod extends StatefulWidget {
  const LiveTod({super.key});

  @override
  State<LiveTod> createState() => _LiveTod();
}

class _LiveTod extends State<LiveTod> {
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
                  child: IconButton(
                    hoverColor: Colors.pink[100],
                    focusColor: Colors.pink[100],
                    highlightColor: Colors.pink[200],
                    alignment: Alignment.bottomCenter,
                    icon: const Icon(
                      Icons.list,
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
            actions: [
              SearchWidget()
            ]),
        body: Container(
            decoration:livetodBackGround(),
            child: ListView(
              children:[
                Text(
                  "还在开发中",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.pink[400],
                    fontSize: 25,
                  ),
                ),
              ],
            )
        ));
  }
}
