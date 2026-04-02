enum ShopOfferKind { card, relic, heal, removeCard }

class ShopOffer {
  const ShopOffer._({
    required this.kind,
    required this.basePrice,
    this.cardId,
    this.relicId,
    this.healAmount = 0,
    this.isHalfPriceSale = false,
    this.isPurchased = false,
  });

  const ShopOffer.card({
    required String cardId,
    required int basePrice,
    bool isHalfPriceSale = false,
    bool isPurchased = false,
  }) : this._(
         kind: ShopOfferKind.card,
         cardId: cardId,
         basePrice: basePrice,
         isHalfPriceSale: isHalfPriceSale,
         isPurchased: isPurchased,
       );

  const ShopOffer.relic({
    required String relicId,
    required int basePrice,
    bool isHalfPriceSale = false,
    bool isPurchased = false,
  }) : this._(
         kind: ShopOfferKind.relic,
         relicId: relicId,
         basePrice: basePrice,
         isHalfPriceSale: isHalfPriceSale,
         isPurchased: isPurchased,
       );

  const ShopOffer.heal({
    required int basePrice,
    required int healAmount,
    bool isHalfPriceSale = false,
    bool isPurchased = false,
  }) : this._(
         kind: ShopOfferKind.heal,
         basePrice: basePrice,
         healAmount: healAmount,
         isHalfPriceSale: isHalfPriceSale,
         isPurchased: isPurchased,
       );

  const ShopOffer.removeCard({
    required int basePrice,
    bool isHalfPriceSale = false,
    bool isPurchased = false,
  }) : this._(
         kind: ShopOfferKind.removeCard,
         basePrice: basePrice,
         isHalfPriceSale: isHalfPriceSale,
         isPurchased: isPurchased,
       );

  factory ShopOffer.fromJson(Map<String, dynamic> json) {
    final kind = ShopOfferKind.values.byName(json['kind'] as String);
    final basePrice = json['basePrice'] as int;
    final isHalfPriceSale = (json['isHalfPriceSale'] as bool?) ?? false;
    final isPurchased = (json['isPurchased'] as bool?) ?? false;
    return switch (kind) {
      ShopOfferKind.card => ShopOffer.card(
        cardId: json['cardId'] as String,
        basePrice: basePrice,
        isHalfPriceSale: isHalfPriceSale,
        isPurchased: isPurchased,
      ),
      ShopOfferKind.relic => ShopOffer.relic(
        relicId: json['relicId'] as String,
        basePrice: basePrice,
        isHalfPriceSale: isHalfPriceSale,
        isPurchased: isPurchased,
      ),
      ShopOfferKind.heal => ShopOffer.heal(
        basePrice: basePrice,
        healAmount: json['healAmount'] as int,
        isHalfPriceSale: isHalfPriceSale,
        isPurchased: isPurchased,
      ),
      ShopOfferKind.removeCard => ShopOffer.removeCard(
        basePrice: basePrice,
        isHalfPriceSale: isHalfPriceSale,
        isPurchased: isPurchased,
      ),
    };
  }

  final ShopOfferKind kind;
  final String? cardId;
  final String? relicId;
  final int basePrice;
  final int healAmount;
  final bool isHalfPriceSale;
  final bool isPurchased;

  String get id => switch (kind) {
    ShopOfferKind.card => 'card:$cardId',
    ShopOfferKind.relic => 'relic:$relicId',
    ShopOfferKind.heal => 'service:heal',
    ShopOfferKind.removeCard => 'service:remove_card',
  };

  int get priceBeforeRunDiscounts =>
      isHalfPriceSale ? (basePrice / 2).round() : basePrice;

  ShopOffer copyWith({
    bool? isHalfPriceSale,
    bool? isPurchased,
  }) {
    return ShopOffer._(
      kind: kind,
      cardId: cardId,
      relicId: relicId,
      basePrice: basePrice,
      healAmount: healAmount,
      isHalfPriceSale: isHalfPriceSale ?? this.isHalfPriceSale,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'cardId': cardId,
    'relicId': relicId,
    'basePrice': basePrice,
    'healAmount': healAmount,
    'isHalfPriceSale': isHalfPriceSale,
    'isPurchased': isPurchased,
  };
}
