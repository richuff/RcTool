import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:get/get.dart';
import 'package:rctool/constant/playlist_const.dart';
import 'package:rctool/page/about_author.dart';
import 'package:rctool/page/AlbumPage/album.dart';
import 'package:rctool/page/AlbumPage/playlist_detail_page.dart';
import 'package:rctool/page/MusicPages/music_choose.dart';
import 'package:rctool/page/MusicPages/music_page.dart';
import 'package:rctool/page/OfflinePage/offline_page.dart';
import 'package:rctool/page/PlayerPage/now_playing_page.dart';
import 'package:rctool/page/SearchPage/search_page.dart';
import 'package:rctool/page/SettingsPage/wallpaper_page.dart';
import 'package:rctool/page/HistoryPage/play_history_page.dart';
import 'package:rctool/page/StatsPage/play_stats_page.dart';
import 'package:rctool/page/live_to_d.dart';
import 'package:rctool/page/RankingPage/ranking.dart';
import 'package:rctool/page/RecommendPages/recommend_music.dart';
import 'package:rctool/repository/entity/playlist.dart';
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
      name: RoutePath.PLAYLIST,
      page: () {
        final args = Get.arguments;
        // 未传参数时兜底为「我的喜欢」，避免直接访问路由时崩溃
        final playlist = args is Playlist ? args : favoritePlaylist();
        return PlaylistDetailPage(playlist: playlist);
      },
      transition: Transition.rightToLeft),
  GetPage(
      name: RoutePath.HISTORY,
      page: () => const PlayHistoryPage(),
      transition: Transition.rightToLeft),
  GetPage(
      name: RoutePath.STATS,
      page: () => const PlayStatsPage(),
      transition: Transition.rightToLeft),


  GetPage(
      name: RoutePath.ABOUT,
      page: () => const AboutAuthor(),
      transition: Transition.rightToLeft),


  GetPage(
      name: RoutePath.SEARCH,
      page: () => const SearchPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200)),
  GetPage(
      name: RoutePath.PLAYER,
      page: () => const NowPlayingPage(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 280)),
  GetPage(
      name: RoutePath.OFFLINE,
      page: () => const OfflinePage(),
      transition: Transition.rightToLeft),
  GetPage(
      name: RoutePath.WALLPAPER,
      page: () => const WallpaperPage(),
      transition: Transition.rightToLeft),
  GetPage(
      name: RoutePath.LIVETOD,
      page: () => const LiveTod(),
      transition: Transition.rightToLeft)
];
