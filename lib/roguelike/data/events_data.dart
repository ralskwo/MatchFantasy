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

enum EventOutcomeType { gainGold, loseHp, gainRelic, gainCards, gainGoldLoseHp, shopDiscount, gainHp }

class EventOutcome {
  const EventOutcome({
    required this.type,
    this.value = 0,
    this.goldBonus = 0,
    this.relicId,
    this.cardCount = 0,
  });
  final EventOutcomeType type;
  final int value;
  final int goldBonus;
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
    id: 'wandering_trader',
    title: '방랑 상인',
    description: '낡은 짐수레를 끌고 온 상인이 윙크한다. "오늘만 특가요!"',
    choices: [
      EventChoice(
        label: '반값 세일 받기',
        description: '다음 상점 방문 시 모든 가격 50% 할인',
        effect: EventOutcome(type: EventOutcomeType.shopDiscount),
      ),
      EventChoice(
        label: '필요 없어',
        description: '골드 +5',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 5),
      ),
    ],
  ),
  GameEvent(
    id: 'ancient_tome',
    title: '고대 서적',
    description: '먼지 쌓인 책에서 원소 문자가 빛을 발한다.',
    choices: [
      EventChoice(
        label: '읽어본다',
        description: '랜덤 카드 1장 획득, HP -10',
        effect: EventOutcome(
          type: EventOutcomeType.gainCards,
          value: -10,
          cardCount: 1,
        ),
      ),
      EventChoice(
        label: '덮어둔다',
        description: '골드 +15',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 15),
      ),
    ],
  ),
  GameEvent(
    id: 'dark_bargain',
    title: '어둠의 계약',
    description: '그림자 속 목소리가 속삭인다. "피 한 방울만 주면..."',
    choices: [
      EventChoice(
        label: '계약 수락',
        description: '골드 +40, HP -15',
        effect: EventOutcome(type: EventOutcomeType.gainGoldLoseHp, value: -15, goldBonus: 40),
      ),
      EventChoice(
        label: '거절한다',
        description: '아무 일도 없다',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 0),
      ),
    ],
  ),
  GameEvent(
    id: 'elemental_spring',
    title: '원소의 샘',
    description: '다섯 원소의 기운이 샘 주위를 돌고 있다.',
    choices: [
      EventChoice(
        label: '몸을 담근다',
        description: 'HP +12',
        effect: EventOutcome(type: EventOutcomeType.gainHp, value: 12),
      ),
      EventChoice(
        label: '원소를 흡수한다',
        description: 'HP -5, Uncommon 유물 획득',
        effect: EventOutcome(type: EventOutcomeType.gainRelic, value: -5),
      ),
    ],
  ),
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
