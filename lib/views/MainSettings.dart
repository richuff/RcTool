import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rctool/feature/Theme/TypeValue.dart';

class MainSettings extends StatefulWidget{
  const MainSettings({super.key});

  @override
  State<StatefulWidget> createState() => _MainSettings();
}

class _MainSettings extends State<MainSettings>{
  bool _isSwitched = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _readData();
    });
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(playKey, _isSwitched);
  }

  Future<void> _readData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitched = prefs.getBool(playKey)!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start ,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(6, 12, 0, 0),
          child: const Text("是否开启自动播放",style: TextStyle(fontSize: 20),),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(4, 2, 0, 0),
          alignment: Alignment.topLeft,
          child: Switch(
            value: _isSwitched,
            onChanged: (bool value) {
              setState(() {
                _isSwitched = value;
              });
              _saveData();
            },
            activeColor: Colors.white, // 开启时的颜色
            inactiveThumbColor: Colors.white, // 关闭时的滑块颜色
            inactiveTrackColor: const Color.fromARGB(255, 219, 219, 219),
            activeTrackColor: const Color.fromARGB(255,38, 52, 115), // 打开时的轨道颜色
          ),
        )
      ],
    );
  }

}