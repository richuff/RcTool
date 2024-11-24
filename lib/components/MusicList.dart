import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MusicList extends StatefulWidget {
  const MusicList({super.key});

  @override
  State<MusicList> createState() => _MusicList();
}

class _MusicList extends State<MusicList> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(8, 20, 0, 12),
          width: double.infinity,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.pink[200],
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(255, 20, 147, 0.4),
                Color.fromRGBO(255, 80, 107, 0.4),
                Color.fromRGBO(255, 105, 180, 0.4)
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(255, 105, 180, 0.4),
                blurRadius: 10.0,
              )
            ],
          ),
        ),
        Positioned(
            left: 8,
            top: 0,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                image: const DecorationImage(
                    image: NetworkImage(
                        "https://img.meituan.net/csc/d05518606ba7064dd445508e3cf3d4c42860983.png"),
                    fit: BoxFit.cover),
                color: Colors.pink[100],
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
            )),
        const Positioned(
          left: 100,
          bottom: 20,
          child: Text("致无暇之人 --- True"),
        ),
        Positioned(
            right: 45,
            bottom: 8,
            child: IconButton(
                onPressed: () => {},
                icon: const Icon(
                  Icons.play_arrow_sharp,
                  color: Colors.white,
                ))),
        Positioned(
            right: 2,
            bottom: 8,
            child: IconButton(
                onPressed: () => {},
                icon: const Icon(
                  Icons.queue_music_sharp,
                  color: Colors.white,
                )))
      ],
    );
  }
}
