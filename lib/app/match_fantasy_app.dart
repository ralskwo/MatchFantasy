import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/router.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/game/ui/game_palette.dart';

class MatchFantasyApp extends StatelessWidget {
  const MatchFantasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: GamePalette.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: GamePalette.accent,
      secondary: GamePalette.secondaryAccent,
      surface: const Color(0xFF12233A),
    );

    return ChangeNotifierProvider(
      create: (_) => RunState(),
      child: MaterialApp.router(
        title: 'Match Fantasy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: GamePalette.backgroundTop,
          cardTheme: const CardThemeData(
            color: Color(0xCC102035),
            elevation: 0,
            margin: EdgeInsets.zero,
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
