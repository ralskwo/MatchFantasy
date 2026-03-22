import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class ClassPassiveApplier {
  /// 클래스 패시브 버스트 데미지 배율 추가분
  static double burstDamageBonus(RunState run) {
    switch (run.selectedClass?.id) {
      case PlayerClassId.emberKnight:
        return 0.30;
      default:
        return 0.0;
    }
  }

  /// Tide Sage: Tide 매치 마나 보정 배율 (2배)
  static double tideManaMultiplier(RunState run) {
    if (run.selectedClass?.id == PlayerClassId.tideSage) return 2.0;
    return 1.0;
  }

  /// Bloom Warden: Bloom 버스트 시 추가 실드
  static int bloomBurstShieldBonus(RunState run) {
    if (run.selectedClass?.id == PlayerClassId.bloomWarden) return 3;
    return 0;
  }
}
