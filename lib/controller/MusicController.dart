import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:rctool/entity/Music.dart';

class MusicController extends GetxController {
  RxList musiclist = [{
    "url":
    "https://img.sobot.com/56b093dec73c42dca06a96734ffa6258/chatres/56b093dec73c42dca06a96734ffa6258/msg/20250103/a1563905111d66f5033927df2f544f83/e2e58620858c4826bbe5f125e519d72a.mp3",
    "imageUrl":
    "https://img.sobot.com/56b093dec73c42dca06a96734ffa6258/chatres/56b093dec73c42dca06a96734ffa6258/msg/20250103/a1563905111d66f5033927df2f544f83/05fbf24ccc20411d87ed953dcdbdb523.jpg",
    "songName": "TruE",
    "decoration": "黄龄"
  },
    {
      "url":
      "https://img.sobot.com/56b093dec73c42dca06a96734ffa6258/chatres/56b093dec73c42dca06a96734ffa6258/msg/20250103/a1563905111d66f5033927df2f544f83/e2e58620858c4826bbe5f125e519d72a.mp3",
      "imageUrl":
      "https://img.sobot.com/56b093dec73c42dca06a96734ffa6258/chatres/56b093dec73c42dca06a96734ffa6258/msg/20250103/a1563905111d66f5033927df2f544f83/9608781f5f46425c8becdfa4ad7e1070.jpg",
      "songName": "TruE",
      "decoration": "黄龄"
    },
    {
      "url":
      "https://img.sobot.com/56b093dec73c42dca06a96734ffa6258/chatres/56b093dec73c42dca06a96734ffa6258/msg/20250103/a1563905111d66f5033927df2f544f83/5157be0bac044cc6ae93815f003b9c86.flac",
      "imageUrl":
      "https://img.sobot.com/56b093dec73c42dca06a96734ffa6258/chatres/56b093dec73c42dca06a96734ffa6258/msg/20250103/a1563905111d66f5033927df2f544f83/7f426ff5e4294a698470e3a9ebd9b2e1.jpg",
      "songName": "Inside you",
      "decoration": "milet"
    }].obs;

  inc(Music music){
    musiclist.add(music);
    update();
  }
  dec(Music music){
    musiclist.remove(music);
    update();
  }
}