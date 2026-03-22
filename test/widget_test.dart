import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/app/match_fantasy_app.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';

void main() {
  testWidgets('app boots and shows main menu', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: MetaState(),
        child: const MatchFantasyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
