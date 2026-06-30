import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:rctool/page/about_author.dart';
import 'package:rctool/page/AlbumPage/album.dart';
import 'package:rctool/page/MusicPages/music_choose.dart';
import 'package:rctool/page/MusicPages/music_like.dart';
import 'package:rctool/page/MusicPages/music_page.dart';
import 'package:rctool/page/live_to_d.dart';
import 'package:rctool/page/RankingPage/ranking.dart';
import 'package:rctool/page/RecommendPages/recommend_music.dart';
import 'package:rctool/routers/route_path.dart';

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
      page: () => const EverydayMusic(),
      transition: Transition.rightToLeft
  ),
  GetPage(name: RoutePath.RANKING,
      page: () => const Ranking(),
      transition: Transition.rightToLeft),
  GetPage(name: RoutePath.ALBUM,
      page: () => const Album(),
      transition: Transition.rightToLeft),


  GetPage(
      name: RoutePath.ABOUT,
      page: () => const AboutAuthor(),
      transition: Transition.rightToLeft),


  GetPage(
      name: RoutePath.LIVETOD,
      page: () => const LiveTod(),
      transition: Transition.rightToLeft)
];