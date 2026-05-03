import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/game/models/battle_presentation_event.dart';
import 'package:match_fantasy/game/systems/battle_presentation_driver.dart';

void main() {
  test('driver dispatches queued events once their delay expires', () {
    final BattlePresentationDriver driver = BattlePresentationDriver();
    final List<BattlePresentationEvent> dispatched =
        <BattlePresentationEvent>[];

    driver.enqueue(const <BattlePresentationEvent>[
      ComboBannerPresentationEvent(comboCount: 3),
      ComboBannerPresentationEvent(comboCount: 4, delayMs: 50),
      ComboBannerPresentationEvent(comboCount: 5),
    ]);

    driver.flushReady(dispatched.add);
    expect(
      dispatched.map((BattlePresentationEvent event) {
        return (event as ComboBannerPresentationEvent).comboCount;
      }),
      <int>[3],
    );

    driver.update(0.03, dispatched.add);
    expect(dispatched, hasLength(1));

    driver.update(0.03, dispatched.add);
    expect(
      dispatched.map((BattlePresentationEvent event) {
        return (event as ComboBannerPresentationEvent).comboCount;
      }),
      <int>[3, 4, 5],
    );
    expect(driver.isEmpty, isTrue);
  });
}
