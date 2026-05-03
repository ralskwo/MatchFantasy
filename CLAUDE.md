# MatchFantasy — Claude Instructions

## 최우선 가드레일

이 저장소에서는 문서 동기화를 코드와 같은 우선순위로 취급한다.

- 작업 시작 전 반드시 `MEMORY.md`, `docs/collaboration/WORKFLOW_GUARDRAIL.md`, `docs/versions/CHANGELOG.md`의 최신 항목을 확인한다.
- 작업 중 변경사항이 생기면 관련 버전 문서와 현재 상태 문서를 함께 갱신한다.
- 프로세스 규칙이 바뀌면 `AGENTS.md`와 이 파일을 같은 작업에서 함께 수정한다.
- 완료를 선언하기 전에 실제 검증 상태를 문서에 남긴다.

## 공유 문서 계약

- `MEMORY.md`: 가장 최근 상태, 오픈 이슈, 최신 버전 포인터
- `docs/project/current-state.md`: 구조, 기능, 검증 현황 기준선
- `docs/versions/CHANGELOG.md`: 버전 인덱스
- `docs/versions/*.md`: 버전별 작업 기록
- `docs/collaboration/WORKFLOW_GUARDRAIL.md`: 상세 운영 규칙

## Skills (Superpowers)

이 프로젝트에서 Claude는 아래 시점에 반드시 해당 스킬을 먼저 호출해야 한다.

| 시점 | 호출 스킬 |
|------|-----------|
| 새 작업 또는 새 세션 시작 시 | `using-superpowers` |
| 새 기능 추가 / 컴포넌트 구현 전 | `superpowers:brainstorming` |
| 버그·테스트 실패·예상치 못한 동작 발생 시 | `superpowers:systematic-debugging` |
| 구현 완료 후 검증 전 | `superpowers:verification-before-completion` |
| 코드 리뷰 피드백을 받았을 때 | `superpowers:receiving-code-review` |
| 멀티스텝 구현 계획이 있을 때 | `superpowers:writing-plans` |
| 독립적인 태스크 2개 이상을 병렬 처리할 때 | `superpowers:dispatching-parallel-agents` |
| 브랜치 작업 마무리 시 | `superpowers:finishing-a-development-branch` |

> 1%라도 해당 스킬이 필요할 것 같으면 반드시 먼저 호출한다.

## 프로젝트 개요

- **엔진**: Flutter + Flame 1.35.1
- **장르**: 세로 화면 매치-3 × 몬스터 웨이브 하이브리드
- **플랫폼**: Windows 중심 개발, Android/iOS 대응 예정

## 주요 구조

```text
lib/
├── main.dart
├── app/match_fantasy_app.dart
├── game/
│   ├── match_fantasy_game.dart
│   ├── models/
│   ├── systems/
│   │   ├── board_engine.dart
│   │   ├── combat_resolver.dart
│   │   └── wave_controller.dart
│   └── ui/
└── roguelike/
    ├── data/
    ├── models/
    ├── screens/
    └── state/
```

## 코딩 규칙

- Dart 분석 경고 0 유지 (`flutter analyze --no-fatal-infos`)
- 가능하면 기존 파일 편집 우선
- 불필요한 주석·docstring 추가 금지
- 변경 후 `flutter analyze`와 필요 시 `flutter test` 결과를 문서에 기록
