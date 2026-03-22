import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/game/systems/combat_resolver.dart';

class RelicEffectApplier {
  /// 전투 시작 시 RunState 유물 효과 적용
  static void applyOnCombatStart(RunState run, SessionResources resources) {
    for (final relic in run.relics) {
      switch (relic.effect.tag) {
        case RelicEffectTag.startHp:
          resources.heal(relic.effect.value.toInt());
          break;
        case RelicEffectTag.startMana:
          resources.addMana(relic.effect.value.toInt());
          break;
        default:
          break;
      }
    }
  }

  /// 버스트 데미지 배율 합산 (예: 1.0 + 0.15 + 0.10 = 1.25)
  static double burstDamageMultiplier(RunState run) {
    double mult = 1.0;
    for (final relic in run.relics) {
      if (relic.effect.tag == RelicEffectTag.burstDamage) {
        mult += relic.effect.value;
      }
    }
    return mult;
  }

  /// 몬스터 처치 시 추가 효과
  static void applyOnKill(RunState run, SessionResources resources) {
    for (final relic in run.relics) {
      if (relic.effect.tag == RelicEffectTag.onKillMana) {
        resources.addMana(relic.effect.value.toInt());
      }
      if (relic.effect.tag == RelicEffectTag.onKillShield) {
        resources.addShield(relic.effect.value.toInt());
      }
    }
  }
}
