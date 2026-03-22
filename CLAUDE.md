# MatchFantasy — Claude Instructions

## Skills (Superpowers)

이 프로젝트에서 Claude는 아래 시점에 반드시 해당 스킬을 먼저 호출해야 한다.

| 시점 | 호출 스킬 |
|------|-----------|
| 새 기능 추가 / 컴포넌트 구현 전 | `superpowers:brainstorming` |
| 버그·테스트 실패·예상치 못한 동작 발생 시 | `superpowers:systematic-debugging` |
| 구현 완료 후 검증 전 | `superpowers:verification-before-completion` |
| 코드 리뷰 피드백을 받았을 때 | `superpowers:receiving-code-review` |
| 멀티스텝 구현 계획이 있을 때 | `superpowers:writing-plans` |
| 독립적인 태스크 2개 이상을 병렬 처리할 때 | `superpowers:dispatching-parallel-agents` |
| 브랜치 작업 마무리 시 | `superpowers:finishing-a-development-branch` |

> 1 % 라도 해당 스킬이 필요할 것 같으면 반드시 먼저 호출한다.

## 프로젝트 개요

- **엔진**: Flutter + Flame 1.35.1
- **장르**: 세로 화면 매치-3 × 몬스터 웨이브 하이브리드
- **플랫폼**: Windows (440×860 portrait 창), Android/iOS 대응 예정

## 주요 구조

```
lib/
├── main.dart
├── app/match_fantasy_app.dart
└── game/
    ├── match_fantasy_game.dart   ← Flame 게임 오케스트레이터
    ├── models/                   ← 데이터 모델
    ├── systems/
    │   ├── board_engine.dart     ← 매치-3 로직 (7×7 그리드)
    │   ├── combat_resolver.dart  ← 데미지/점수
    │   └── wave_controller.dart  ← 몬스터 웨이브
    └── ui/
        ├── game_hud_overlay.dart
        └── game_palette.dart
```

## 코딩 규칙

- Dart 분석 경고 0 유지 (`flutter analyze --no-fatal-infos`)
- 새 파일 생성보다 기존 파일 편집 우선
- 불필요한 주석·docstring 추가 금지
- 변경 후 반드시 `flutter analyze` 통과 확인
