import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widget/Mydialog.dart';

class TestPage extends StatefulWidget{
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPage();
}

class _TestPage extends State<TestPage>{

  @override
  Widget build(BuildContext context) {
    void _mydialog() async {
      var res = await showDialog(
          context: context,
          builder: (context) {
            return Mydialog(
              title: "提示",
              content: "我是提示",
              onTab: () {
                //点击按钮关闭
              },
            );
          });
      print(res);
    }

    return ListView(
      children: [
        ElevatedButton(onPressed: ()=>{
          _mydialog()
        }, child: const Text("test"))
      ],
    );
  }
}