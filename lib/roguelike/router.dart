import 'package:go_router/go_router.dart';
import 'package:match_fantasy/roguelike/screens/main_menu_screen.dart';
import 'package:match_fantasy/roguelike/screens/class_select_screen.dart';
import 'package:match_fantasy/roguelike/screens/relic_select_screen.dart';
import 'package:match_fantasy/roguelike/screens/run_map_screen.dart';
import 'package:match_fantasy/roguelike/screens/upgrade_screen.dart';
import 'package:match_fantasy/roguelike/screens/shop_screen.dart';
import 'package:match_fantasy/roguelike/screens/event_screen.dart';
import 'package:match_fantasy/roguelike/screens/rest_screen.dart';
import 'package:match_fantasy/roguelike/screens/combat_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',        builder: (ctx, state) => const MainMenuScreen()),
    GoRoute(path: '/class',   builder: (ctx, state) => const ClassSelectScreen()),
    GoRoute(path: '/relic',   builder: (ctx, state) => const RelicSelectScreen()),
    GoRoute(path: '/map',     builder: (ctx, state) => const RunMapScreen()),
    GoRoute(path: '/upgrade', builder: (ctx, state) => const UpgradeScreen()),
    GoRoute(path: '/shop',    builder: (ctx, state) => const ShopScreen()),
    GoRoute(path: '/event',   builder: (ctx, state) => const EventScreen()),
    GoRoute(path: '/rest',    builder: (ctx, state) => const RestScreen()),
    GoRoute(path: '/combat',  builder: (ctx, state) => const CombatScreen()),
  ],
);
