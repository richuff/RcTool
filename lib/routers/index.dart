import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:rctool/page/AboutAuthor.dart';
import 'package:rctool/page/MusicPages/MusicChoose.dart';
import 'package:rctool/page/MusicPages/MusicLike.dart';
import 'package:rctool/page/MusicPages/MusicPage.dart';
import 'package:rctool/page/LiveTod.dart';
import 'package:rctool/page/RecommendPages/EveryDayMusic.dart';

var routes = [
  GetPage(
      name: "/music",
      page: () => const MusicPage(),
      transition: Transition.rightToLeft
  ),
  GetPage(
      name: "/musicchoose",
      page: () => const MusicChoose(),
      transition: Transition.rightToLeft
  ),
  GetPage(
      name: "/musiclike",
      page: () => const MusicLike(),
      transition: Transition.rightToLeft
  ),
  GetPage(
      name: "/recommend",
      page: () => const Everydaymusic(),
      transition: Transition.rightToLeft
  ),



  GetPage(
      name: "/about",
      page: () => const AboutAuthor(),
      transition: Transition.rightToLeft),



  GetPage(
      name: "/livetod",
      page: () => const LiveTod(),
      transition: Transition.rightToLeft)
];