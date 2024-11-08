import 'package:flutter/material.dart';
import 'package:rctool/components/MusicCard.dart';
import 'package:rctool/components/MusicPlayer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RcTool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.pink[50],
          leading: Column(children: [
            const Padding(padding: EdgeInsets.only(top: 8)),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                hoverColor: Colors.pink[100],
                focusColor: Colors.pink[100],
                highlightColor: Colors.pink[200],
                alignment: Alignment.bottomCenter,
                icon: const Icon(Icons.list),
                color: Colors.black,
                onPressed: () {
                  print("侧边栏");
                },
              ),
            ),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: IconButton(
                  hoverColor: Colors.pink[100],
                  focusColor: Colors.pink[100],
                  highlightColor: Colors.pink[200],
                  onPressed: () {
                    print("搜索栏");
                  },
                  icon: const Icon(Icons.search)),
            )
          ]),
      body:const Column(
        children: [
          MusicCard(),
          MusicPlayer()
        ],
      )
    );
  }
}
