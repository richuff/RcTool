import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:rctool/page/AboutAuthor.dart';
import 'package:rctool/page/MusicPage.dart';
import 'package:rctool/page/TestPage.dart';

var routes = [
  GetPage(
      name: "/music",
      page: () => const MusicPage(),
      transition: Transition.rightToLeft
  ),

  GetPage(
      name: "/about",
      page: () => const AboutAuthor(),
      transition: Transition.rightToLeft),
  GetPage(
      name: "/test",
      page: () => const TestPage(),
      transition: Transition.rightToLeft)
];