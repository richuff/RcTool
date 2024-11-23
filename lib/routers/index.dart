import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:rctool/page/MusicPage.dart';

var routes = [
  GetPage(
      name: "/music",
      page: () => const MusicPage(),
      transition: Transition.rightToLeft)
];