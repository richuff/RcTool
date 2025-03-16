import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:rctool/page/AboutAuthor.dart';
import 'package:rctool/page/MusicPages/MusicChoose.dart';
import 'package:rctool/page/MusicPages/MusicLike.dart';
import 'package:rctool/page/MusicPages/MusicPage.dart';
import 'package:rctool/page/LiveTod.dart';
import 'package:rctool/page/RecommendPages/RecommendMusic.dart';
import 'package:rctool/routers/RoutePath.dart';

var routes = [
  GetPage(
      name: RoutePath.MUSIC,
      page: () => const MusicPage(),
      transition: Transition.rightToLeft
  ),
  GetPage(
      name: RoutePath.MUSICCHOOSE,
      page: () => const MusicChoose(),
      transition: Transition.rightToLeft
  ),
  GetPage(
      name: RoutePath.MUSICLIKE,
      page: () => const MusicLike(),
      transition: Transition.rightToLeft
  ),
  GetPage(
      name: RoutePath.RECOMMEND,
      page: () => const Everydaymusic(),
      transition: Transition.rightToLeft
  ),



  GetPage(
      name: RoutePath.ABOUT,
      page: () => const AboutAuthor(),
      transition: Transition.rightToLeft),



  GetPage(
      name: RoutePath.LIVETOD,
      page: () => const LiveTod(),
      transition: Transition.rightToLeft)
];