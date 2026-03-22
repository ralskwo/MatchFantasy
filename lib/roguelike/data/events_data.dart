class EventChoice {
  const EventChoice({
    required this.label,
    required this.description,
    required this.effect,
  });
  final String label;
  final String description;
  final EventOutcome effect;
}

enum EventOutcomeType { gainGold, loseHp, gainRelic, gainCards, gainGoldLoseHp }

class EventOutcome {
  const EventOutcome({
    required this.type,
    this.value = 0,
    this.relicId,
    this.cardCount = 0,
  });
  final EventOutcomeType type;
  final int value;
  final String? relicId;
  final int cardCount;
}

class GameEvent {
  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
  });
  final String id;
  final String title;
  final String description;
  final List<EventChoice> choices;
}

const List<GameEvent> allEvents = [
  GameEvent(
    id: 'altar',
    title: '버려진 제단',
    description: '희미한 원소의 기운이 감돈다.',
    choices: [
      EventChoice(
        label: '제물 바치기',
        description: 'HP -8, Uncommon 유물 획득',
        effect: EventOutcome(type: EventOutcomeType.gainRelic, value: -8),
      ),
      EventChoice(
        label: '그냥 지나친다',
        description: '골드 +10',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 10),
      ),
    ],
  ),
  GameEvent(
    id: 'merchant',
    title: '수상한 거래',
    description: '싸구려처럼 보이지만 빛이 난다.',
    choices: [
      EventChoice(
        label: '구매 (골드 -30)',
        description: '랜덤 카드 3장 획득',
        effect: EventOutcome(
          type: EventOutcomeType.gainCards,
          value: -30,
          cardCount: 3,
        ),
      ),
      EventChoice(
        label: '거절',
        description: '없음',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 0),
      ),
    ],
  ),
  GameEvent(
    id: 'rift',
    title: '원소 균열',
    description: '보드가 흔들린다.',
    choices: [
      EventChoice(
        label: '수용',
        description: '버스트 데미지 +15%, 다음 전투 HP -5',
        effect: EventOutcome(
          type: EventOutcomeType.gainGoldLoseHp,
          value: -5,
        ),
      ),
      EventChoice(
        label: '봉인',
        description: '골드 +20',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 20),
      ),
    ],
  ),
];
