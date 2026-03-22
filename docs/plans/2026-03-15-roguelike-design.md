# MatchFantasy — Roguelike System Design
**Date:** 2026-03-15
**Status:** Approved

---

## 1. 전체 아키텍처

### 접근 방식
Flutter 라우터가 화면 전환을 담당하고, Flame은 전투 노드에서만 활성화.

### 화면 흐름

```
앱 시작
  └─ MainMenuScreen (Flutter)
       └─ [런 시작]
            └─ ClassSelectScreen (Flutter)
                 └─ RelicSelectScreen (Flutter)
                      └─ RunMapScreen (Flutter)
                           ├─ CombatNode  → MatchFantasyGame (Flame)
                           │                  └─ 전투 종료 → UpgradeScreen (Flutter)
                           ├─ ShopNode    → ShopScreen (Flutter)
                           ├─ EventNode   → EventScreen (Flutter)
                           └─ BossNode    → MatchFantasyGame (Flame, 보스 전용 WaveProfile)
```

### 상태 구조

```dart
// 런 중 유지 (런 종료 시 소멸)
class RunState extends ChangeNotifier {
  PlayerClass selectedClass;
  List<Relic> currentRelics;
  List<UpgradeCard> acquiredCards;
  MapNode currentNode;
  int health;
  int maxHealth;
  int gold;
  int actNumber;
}

// 영구 저장 (SharedPreferences)
class MetaState extends ChangeNotifier {
  int currency;
  Set<String> unlockedClasses;
  Set<String> unlockedRelics;
  Map<String, int> achievementProgress;
  Map<String, int> highScores;
  int totalRuns;
  int totalKills;
}
```

`RunState` / `MetaState`는 `ChangeNotifierProvider`로 Flutter 트리에 주입.
Flame 전투 진입 시 `RunState`를 읽어 보드·웨이브 파라미터 세팅, 전투 종료 결과를 `RunState`에 기록 후 `RunMapScreen` 복귀.

---

## 2. 노드 맵

### 구조
- Act 3개, Act당 4~5행, 행마다 분기 2~3개
- 같은 행의 노드 중 하나만 선택 가능
- 맵은 런 시작 시 시드 기반 랜덤 생성 (재현 가능)
- 방문한 노드 비활성, 선택 가능한 노드만 강조

### 노드 종류

| 노드 | 빈도 | 내용 |
|------|------|------|
| ⚔️ 전투 | 50% | 웨이브 세트 클리어 → 업그레이드 카드 3장 선택 |
| 💀 엘리트 전투 | 10% | 강화된 웨이브, 클리어 시 유물 1개 획득 |
| 🏪 상점 | 15% | 골드로 카드·유물·HP 회복 구매 |
| 📜 이벤트 | 15% | 선택형 텍스트 이벤트 (리스크/리워드) |
| 😴 휴식 | 10% | HP 30% 회복 또는 카드 1장 업그레이드 |
| 👑 보스 | Act 끝 | 보스 전용 WaveProfile, 클리어 시 희귀 유물 |

### 골드 획득
- 일반 전투 클리어: 15~25골드
- 엘리트 클리어: 30~45골드
- 이벤트 보상: 0~30골드

---

## 3. 클래스 & 유물

### 5가지 클래스

| 클래스 | 원소 | 패시브 특성 | 시작 유물 |
|--------|------|------------|----------|
| Ember Knight | 🔥 Ember | Ember 버스트 데미지 +30% | 불꽃 인장 |
| Tide Sage | 🌊 Tide | Tide 매치 시 마나 2배 회복 | 조류석 |
| Bloom Warden | 🌿 Bloom | Bloom 버스트 시 실드 추가 부여 | 생명의 씨앗 |
| Spark Trickster | ⚡ Spark | Spark 슬로우 효과 2배 지속 | 번개 깃털 |
| Umbra Reaper | 🌑 Umbra | Umbra AOE 범위 +1칸 | 어둠의 낫 |

초기 해금: Ember Knight만. 나머지는 메타 진행으로 개방.

### 시작 유물 선택
클래스 선택 후 → 클래스 전용 Common 유물 2개 + 범용 Common 1개, 총 3장 중 1개 선택.

### 유물 등급

**Common**
- 낡은 투구: 전투 시작 HP +3
- 마나 결정: 매치 5회마다 마나 +5
- 행운의 동전: 상점 가격 -10%

**Uncommon**
- 쌍둥이 원소석: 2가지 원소 동시 버스트 시 데미지 +25%
- 모래시계: 메테오 발동 시 3초간 몬스터 이동 정지
- 파편 갑옷: 몬스터 처치마다 실드 +1

**Rare**
- 피닉스 깃털: 런 중 1회 HP 1에서 부활, HP 절반 회복
- 원소 공명: 보드에 같은 원소 4개 이상 시 매 초 마나 +1
- 혼돈의 주사위: 매 웨이브 시작 시 랜덤 버프/디버프

**Boss Relic**
- 왕의 인장: 모든 원소 버스트 데미지 +15%
- 시간의 심장: 메테오 발동마다 최전방 몬스터 즉사
- 공허의 핵: Umbra 버스트 시 처치된 몬스터 수만큼 마나 회복

---

## 4. 런 중 업그레이드

### 업그레이드 카드
전투 클리어 후 3장 중 1장 선택. 최대 10장 소지.

**패시브 카드 예시**
- "3매치 시 인접 타일 1개 추가 클리어"
- "스페셜 젬 생성 확률 +15%"
- "버스트 데미지 +10%"
- "Ember+Tide 연속 버스트 시 전체 데미지 +20%"

**액티브 카드 예시**

| 카드 | 효과 | 사용 횟수/전투 |
|------|------|--------------|
| 원소 폭발 | 특정 원소 타일 전부 클리어 | 1 |
| 보호막 충전 | 실드 +8 즉시 | 2 |
| 타임 슬립 | 3초간 몬스터 정지 | 1 |
| 보드 리프레시 | 전체 보드 새로고침 | 1 |

### 이벤트 예시

> 📜 **버려진 제단**
> A: 제물 바치기 (HP -8) → Uncommon 유물 획득
> B: 그냥 지나친다 → 골드 +10

> 📜 **상인의 수상한 거래**
> A: 골드 -30 → 랜덤 카드 3장 획득
> B: 거절 → 없음

> 📜 **원소 균열**
> A: 수용 → 랜덤 원소 패시브 강화, 다음 전투 HP -5
> B: 봉인 → 골드 +20

### 상점 구성

| 슬롯 | 내용 | 가격 |
|------|------|------|
| 카드 3장 | 랜덤 패시브/액티브 | 40~70골드 |
| 유물 2개 | Common~Uncommon | 80~130골드 |
| HP 회복 | +15 HP | 50골드 |
| 카드 제거 | 덱에서 카드 1장 삭제 | 60골드 |

---

## 5. 메타 진행

### 트랙 A — 런 골드 해금

**런 골드 획득 기준**
- 클리어한 노드 수 × 5
- 처치 몬스터 수 × 1
- 남은 HP × 2
- Act 3 최초 클리어 보너스 +100

**해금 트리**

| Tier 1 (50골드) | Tier 2 (120골드) | Tier 3 (250골드) |
|----------------|-----------------|-----------------|
| Tide Sage 해금 | Spark Trickster 해금 | Umbra Reaper 해금 |
| Common 유물 3종 추가 | Uncommon 유물 3종 추가 | Boss Relic 1종 추가 |
| 시작 HP +2 패시브 | 상점 슬롯 +1 | 시작 골드 +20 |

### 트랙 B — 도전 달성

| 업적 | 조건 | 보상 |
|------|------|------|
| 첫 걸음 | Act 1 보스 클리어 | Bloom Warden 해금 |
| 원소 마스터 | 한 런에서 모든 원소 버스트 5회 이상 | 원소 공명 유물 해금 |
| 철벽 | HP 손실 없이 전투 노드 3연속 클리어 | 파편 갑옷 유물 해금 |
| 탐욕 | 한 런에서 상점 3번 방문 | 행운의 동전 유물 해금 |
| 대학살 | 한 런에서 몬스터 200마리 처치 | 혼돈의 주사위 유물 해금 |
| 전설 | Act 3 최종보스 클리어 | 히든 클래스 해금 |

---

## 구현 우선순위

1. **Phase 1 — 런 골격**: RunState, MetaState, 화면 라우팅, ClassSelect, RelicSelect, RunMapScreen (노드 맵 UI)
2. **Phase 2 — 전투 연동**: Flame 게임과 RunState 연결, 전투 결과 반영, UpgradeScreen (카드 선택)
3. **Phase 3 — 상점·이벤트**: ShopScreen, EventScreen, 휴식 노드
4. **Phase 4 — 유물 효과**: 유물별 실제 게임 수치 적용 (CombatResolver, WaveController 연동)
5. **Phase 5 — 메타 진행**: MetaState 영구 저장, 해금 트리 UI, 업적 추적
