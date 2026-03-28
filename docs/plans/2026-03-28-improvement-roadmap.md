# MatchFantasy 개선 로드맵 (Sigil Descent 참고)

> **공유 문서** — Claude / Codex / 개발자가 함께 참조하는 마스터 플랜.
> 각 항목 완료 시 체크박스와 커밋 해시를 업데이트한다.

---

## 배경

`C:\Users\ralskwo\Desktop\Study\Privates\sigil_descent` 를 레퍼런스로 삼아
MatchFantasy의 연출·전략성·콘텐츠를 단계적으로 개선한다.

### 두 프로젝트 핵심 격차

| 영역 | MatchFantasy | Sigil Descent |
|------|-------------|---------------|
| 공격 연출 | 배틀필드 색 파동 | 포물선 발사체 (arcHeight, arcBias) |
| 원소 전략 | 원소 효과만 다름, 데미지 배율 없음 | 속성 상성 (×1.6 / ×0.5) |
| 스킬 충전 | mana 시스템 | 타일 해소 횟수 기반 충전 |
| 특수 타일 | 2종 (line, nova) | 5종 + 조합별 12가지 시너지 |
| 빌드 다양성 | 10개 카드 | 10종 패시브 + 원소 특화 설계 |
| 노드 보상 | 전투 후 카드 3개만 선택 | reward 노드 (카드/렐릭/골드 선택) |

---

## 구현 규칙

- 브랜치: `phase<N>/<slug>` 형식으로 작업, 완료 후 `main` 병합
- 커밋 메시지: `feat/fix/refactor: <설명>` 형식
- 각 항목 구현 전: `docs/superpowers/specs/YYYY-MM-DD-<slug>.md` 작성
- 각 항목 완료 후: 아래 체크박스 + 커밋 해시 기록, `MEMORY.md` 갱신
- 필수 통과: `flutter analyze --no-fatal-infos` (경고 0개)

---

## Phase 1 — 즉시 고품질 효과

### 1-A. 발사체 시스템 (Projectile Volley)
- [x] 구현 완료
- **브랜치**: `phase1/projectile-system`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-projectile-system.md`
- **커밋**: `f809eb5`

**목표**: 공격 연출을 포물선 발사체로 교체해 전투 인과관계 시각화.

**대상 파일**
- `lib/game/match_fantasy_game.dart`
  - `_queueCombatCues()` — 발사체 생성
  - `update()` — 발사체 진행 업데이트
  - `_drawBattlefield()` — 발사체 렌더링

**핵심 구현**
```dart
class _Projectile {
  final Offset startPos;   // 보드 하단 중앙
  final Offset targetPos;  // 대상 몬스터 위치
  final Color color;
  final double duration;   // 0.35s
  final double arcHeight;  // cellSize * 0.9
  double elapsed = 0;

  Offset get currentPos {
    final t = (elapsed / duration).clamp(0.0, 1.0);
    return Offset.lerp(startPos, targetPos, t)!
        + Offset(0, -arcHeight * 4 * t * (1 - t));
  }
}
```
- 목록 크기 제한: max 8개
- 렌더: `drawCircle` (반지름 5px) + 짧은 trail

**완료 기준**
- 버스트 후 발사체가 보드→적 방향 포물선 비행
- fps 유지

---

### 1-B. 속성 상성 시스템 (Element Affinity)
- [x] 구현 완료
- **브랜치**: `phase1/element-affinity`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-element-affinity.md`
- **커밋**: `f809eb5`

**목표**: 몬스터별 강/약 원소 추가로 전략적 원소 선택 유도.

**대상 파일**
- `lib/game/models/monster_state.dart` — `MonsterKindAffinity` extension 추가
- `lib/game/systems/combat_resolver.dart` — 데미지 계산에 배율 적용

**핵심 구현**
```dart
extension MonsterKindAffinity on MonsterKind {
  BlockType? get weakTo => switch (this) {
    MonsterKind.grunt  => BlockType.ember,
    MonsterKind.runner => BlockType.spark,
    MonsterKind.brute  => BlockType.tide,
    MonsterKind.boss   => null,
  };
  BlockType? get resistTo => switch (this) {
    MonsterKind.grunt  => BlockType.umbra,
    MonsterKind.runner => BlockType.bloom,
    MonsterKind.brute  => BlockType.ember,
    MonsterKind.boss   => null,
  };
}
// 배율: 강 1.5×, 약 0.7×
```

**완료 기준**
- Grunt vs ember: ×1.5 데미지
- Grunt vs umbra: ×0.7 데미지

---

### 1-C. 원소 충전 진행률 시각화
- [x] 구현 완료
- **브랜치**: `phase1/charge-bar-ui`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-charge-bar-ui.md`
- **커밋**: `f809eb5`

**목표**: 원소 충전 칩을 숫자에서 progress bar로 교체.

**대상 파일**
- `lib/game/ui/game_hud_overlay.dart` — 원소 칩 Widget 교체

**핵심 구현**
- 아이콘(22px) + LinearProgressIndicator(28×4px) + 숫자(9pt) 수직 배치
- `charge == 10`: Colors.amber + pulse 애니메이션

**완료 기준**
- 매치 시 bar 실시간 증가
- 10 도달 시 amber + 깜박임

---

## Phase 2 — 전략성 강화

### 2-A. 액티브 스킬 충전 시스템
- [ ] 구현 완료
- **브랜치**: `phase2/active-skill-recharge`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-active-skill-recharge.md`
- **커밋**: —

**목표**: 타일 해소 횟수 기반 충전으로 매치 행동에 스킬 충전 의미 부여.

**대상 파일**
- `lib/roguelike/models/upgrade_card.dart` — `rechargeThreshold: int` 추가 (기본 15)
- `lib/game/match_fantasy_game.dart` — `_skillChargeProgress` Map + `_tickActiveSkillCharges()`
- `lib/game/models/hud_state.dart` — 충전 진행 Map 추가
- `lib/game/ui/game_hud_overlay.dart` — 충전 bar 표시

**완료 기준**
- 타일 15개 해소 시 액티브 카드 1회 충전
- HUD에서 진행률 표시

---

### 2-B. Cross Clear 특수 타일
- [ ] 구현 완료
- **브랜치**: `phase2/cross-clear-tile`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-cross-clear-tile.md`
- **커밋**: —

**목표**: `GemSpecialKind.cross`(3×3 폭발) 추가로 조합 경우의 수 확장.

**대상 파일**
- `lib/game/models/gem_tile.dart` — `GemSpecialKind.cross` 추가
- `lib/game/systems/board_engine.dart` — `_specialTargets()`, `_specialsForGroups()` cross 케이스
- `lib/game/match_fantasy_game.dart` — idle glow 초록 ring 추가

**완료 기준**
- cross 활성화 시 3×3 영역 클리어
- idle glow에서 초록 ring 표시

---

### 2-C. 카드 덱 확장 (원소 특화 패시브 5개)
- [x] 구현 완료
- **브랜치**: `phase2/card-deck-expansion`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-card-deck-expansion.md`
- **커밋**: `c13ba29`

**목표**: 원소별 특화 패시브 5개 추가로 빌드 다양성 향상.

**대상 파일**
- `lib/roguelike/data/cards_data.dart` — 5개 카드 추가
- `lib/roguelike/models/upgrade_card.dart` — `CardEffectTag` 확장 (필요 시)

**추가 카드**
| id | 이름 | 효과 |
|----|------|------|
| `ember_chain` | 불꽃 연쇄 | Ember 버스트 후 Spark +30% |
| `tide_leech` | 조류 흡수 | Tide 처치 시 HP +1 |
| `bloom_fortress` | 꽃 요새 | Shield 최대 +15 |
| `spark_overload` | 전기 과부하 | Spark 슬로우 중 데미지 +40% |
| `umbra_reap` | 암흑 수확 | Umbra 처치 시 Mana +5 |

---

## Phase 3 — 콘텐츠 확장

### 3-A. Reward 노드
- [ ] 구현 완료
- **브랜치**: `phase3/reward-node`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-reward-node.md`
- **커밋**: —

**목표**: 전투 후 보상을 카드/렐릭/골드 중 선택하는 분기 보상으로 변경.

**대상 파일**
- `lib/roguelike/models/map_node.dart` — `NodeType.reward` 추가
- `lib/roguelike/models/run_map.dart` — `_pickNodeType()` 조정
- `lib/roguelike/screens/combat_screen.dart` — 비보스 완료 시 `/reward`
- `lib/roguelike/screens/upgrade_screen.dart` — RewardType 분기 처리

---

### 3-B. 몬스터 약점 UI
- [x] 구현 완료
- **브랜치**: `phase3/weakness-ui`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-weakness-ui.md`
- **커밋**: `f809eb5`

**목표**: 몬스터 아이콘 우상단에 약점 원소 아이콘(14px) 표시.

**대상 파일**
- `lib/game/match_fantasy_game.dart` — `_drawBattlefield()` 내 약점 아이콘 렌더링

**핵심 구현**
```dart
final BlockType? weak = monster.kind.weakTo;
if (weak != null) {
  final Rect iconRect = Rect.fromLTWH(
    monsterRect.right - 14, monsterRect.top - 2, 14, 14);
  _drawElementIcon(canvas, weak, iconRect, alpha: 0.9);
}
```

---

### 3-C. 이벤트 확장 + 상점 세일
- [ ] 구현 완료
- **브랜치**: `phase3/event-expansion`
- **Spec**: `docs/superpowers/specs/YYYY-MM-DD-event-expansion.md`
- **커밋**: —

**목표**: 이벤트 3~5개 추가, 상점 반값 세일 이벤트 결과 추가.

**대상 파일**
- `lib/roguelike/data/events_data.dart` — 이벤트 추가, `EventOutcomeType.shopDiscount`
- `lib/roguelike/state/run_state.dart` — `temporaryShopDiscount` 필드
- `lib/roguelike/screens/shop_screen.dart` — 할인 적용 로직

---

## Phase 4 — 폴리싱

### 4-A. BattlePresentation 이벤트 큐 분리
- [ ] 구현 완료
- **브랜치**: `phase4/presentation-planner`
- **커밋**: —

**목표**: sealed class 이벤트 큐로 전투 계산과 연출 분리.

---

### 4-B. 클래스 패시브 완전 구현
- [ ] 구현 완료
- **브랜치**: `phase4/class-passive-complete`
- **커밋**: —

**목표**: SparkTrickster(슬로우 중 ×2), UmbraReaper(처치 시 Umbra 타일 주입) 패시브 구현.

---

### 4-C. 런 요약 화면
- [ ] 구현 완료
- **브랜치**: `phase4/run-summary-screen`
- **커밋**: —

**목표**: 런 종료 시 처치 수, 최대 콤보, 수집 카드 목록 표시.

---

## 진행 현황

| 항목 | 상태 | 커밋 |
|------|------|------|
| 1-C 충전 진행률 bar | ✅ 완료 | `f809eb5` |
| 1-B 속성 상성 | ✅ 완료 | `f809eb5` |
| 3-B 약점 UI | ✅ 완료 | `f809eb5` |
| 1-A 발사체 시스템 | ✅ 완료 | `f809eb5` |
| 2-C 카드 덱 확장 | ✅ 완료 | `c13ba29` |
| 2-A 액티브 충전 | 대기 | — |
| 2-B Cross Clear | 대기 | — |
| 3-A Reward 노드 | 대기 | — |
| 3-C 이벤트 확장 | 대기 | — |
| 4-B 클래스 패시브 | 대기 | — |
| 4-C 런 요약 화면 | 대기 | — |
| 4-A 프레젠테이션 분리 | 대기 | — |

---

*최종 수정: 2026-03-28*
