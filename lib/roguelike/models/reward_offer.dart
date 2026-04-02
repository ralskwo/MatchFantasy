enum RewardOfferKind { card, relic, gold }

class RewardOffer {
  const RewardOffer._({
    required this.kind,
    this.cardId,
    this.relicId,
    this.goldAmount = 0,
  });

  const RewardOffer.card({required String cardId})
      : this._(kind: RewardOfferKind.card, cardId: cardId);

  const RewardOffer.relic({required String relicId})
      : this._(kind: RewardOfferKind.relic, relicId: relicId);

  const RewardOffer.gold({required int goldAmount})
      : this._(kind: RewardOfferKind.gold, goldAmount: goldAmount);

  factory RewardOffer.fromJson(Map<String, dynamic> json) {
    final kind = RewardOfferKind.values.byName(json['kind'] as String);
    return switch (kind) {
      RewardOfferKind.card =>
        RewardOffer.card(cardId: json['cardId'] as String),
      RewardOfferKind.relic =>
        RewardOffer.relic(relicId: json['relicId'] as String),
      RewardOfferKind.gold =>
        RewardOffer.gold(goldAmount: json['goldAmount'] as int),
    };
  }

  final RewardOfferKind kind;
  final String? cardId;
  final String? relicId;
  final int goldAmount;

  String get id => switch (kind) {
    RewardOfferKind.card => 'card:$cardId',
    RewardOfferKind.relic => 'relic:$relicId',
    RewardOfferKind.gold => 'gold:$goldAmount',
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'cardId': cardId,
    'relicId': relicId,
    'goldAmount': goldAmount,
  };
}
