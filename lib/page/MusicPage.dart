import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/widget/SearchWidget.dart';
import '../views/MusicPlayer.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPage();
}

class _MusicPage extends State<MusicPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        width: 250,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.pink[400],
              ),
              child: const Text(
                '工具箱',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('关于作者'),
              onTap: () {
                scaffoldKey.currentState?.closeDrawer();
                Get.toNamed("/about");
              },
            ),
          ],
        ),
      ),
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
          decoration: const BoxDecoration(
            image: DecorationImage(
                opacity: 0.1,
                image: NetworkImage(
                    "https://p0.meituan.net/csc/ac442b7297cabb92da0ad4f114b22660667771.jpg"),
                fit: BoxFit.cover),
          ),
          child: const Column(
            children: [MusicPlayer()],
          )),
    );
  }
}
