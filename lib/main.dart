import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/app/match_fantasy_app.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  final meta = MetaState();
  await meta.load();

  final runState = RunState();
  await runState.tryLoadSave();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: meta),
        ChangeNotifierProvider.value(value: runState),
      ],
      child: const MatchFantasyApp(),
    ),
  );
}
