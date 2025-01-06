import 'package:flutter/material.dart';

class Recommend extends StatefulWidget {
  @override
  State<Recommend> createState() => _Recommend();
}

class _Recommend extends State<Recommend> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 1000,child: ElevatedButton(onPressed: (){}, child: const Text("推荐")),);
  }
}
