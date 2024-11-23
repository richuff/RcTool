import 'package:flutter/material.dart';

class MSCard extends StatefulWidget {
  const MSCard({super.key});

  @override
  State<MSCard> createState() => _MSCard();
}

class _MSCard extends State<MSCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 30),
        width: 300,
        height: 550,
        decoration: BoxDecoration(
            image: const DecorationImage(
                image: NetworkImage(""), fit: BoxFit.cover),
            color: Colors.pink[100],
            borderRadius: const BorderRadius.all(Radius.circular(50.0)),
            boxShadow: const [BoxShadow(color: Colors.pink, blurRadius: 4.0)]),
        child: Stack(
          children: [
            Positioned(
                top: 20,
                right: 35,
                child: Opacity(
                  opacity: 0.7,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white,
                    ),
                    child: IconButton(
                        iconSize: 32,
                        onPressed: () => {print("test")},
                        icon: const Icon(Icons.heart_broken)),
                  ),
                )),
            Positioned(
              bottom: 30,
              right: 35,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.white,
                ),
                child: IconButton(
                    iconSize: 35,
                    onPressed: () => {print("test")},
                    icon: const Icon(Icons.play_arrow_sharp)),
              ),
            ),
            const Positioned(
              bottom: 50,
              left: 30,
              child: Text(
                "Song Name",
                style: TextStyle(fontSize: 24, color: Colors.blueAccent),
              ),
            ),
            const Positioned(
              bottom: 50,
              left: 30,
              child: Text(
                "Song Name",
                style: TextStyle(fontSize: 24, color: Colors.blueAccent),
              ),
            ),
            const Positioned(
                bottom: 20,
                left: 30,
                child: Text(
                  "Artist Name",
                  style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                ))
          ],
        ));
  }
}
