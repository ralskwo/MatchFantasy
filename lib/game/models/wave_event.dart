enum WaveEventType {
  waveStart,
  bossArrival,
  bossShockwave,
  bossRally,
  bossReinforce,
}

class WaveEvent {
  const WaveEvent({required this.type, required this.message});

  final WaveEventType type;
  final String message;
}
