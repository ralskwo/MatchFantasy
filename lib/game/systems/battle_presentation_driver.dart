import 'package:match_fantasy/game/models/battle_presentation_event.dart';

class BattlePresentationDriver {
  final List<_QueuedPresentationEvent> _queue = <_QueuedPresentationEvent>[];

  bool get isEmpty => _queue.isEmpty;

  void clear() {
    _queue.clear();
  }

  void enqueue(Iterable<BattlePresentationEvent> events) {
    for (final BattlePresentationEvent event in events) {
      _queue.add(
        _QueuedPresentationEvent(
          event: event,
          remainingDelay: event.delayMs / 1000,
        ),
      );
    }
  }

  void flushReady(void Function(BattlePresentationEvent event) dispatch) {
    update(0, dispatch);
  }

  void update(
    double dt,
    void Function(BattlePresentationEvent event) dispatch,
  ) {
    if (_queue.isEmpty) {
      return;
    }

    var remainingDt = dt;
    while (_queue.isNotEmpty) {
      final _QueuedPresentationEvent next = _queue.first;
      if (next.remainingDelay > remainingDt) {
        next.remainingDelay -= remainingDt;
        break;
      }

      remainingDt -= next.remainingDelay;
      _queue.removeAt(0);
      dispatch(next.event);

      while (_queue.isNotEmpty && _queue.first.remainingDelay <= 0) {
        dispatch(_queue.removeAt(0).event);
      }

      if (remainingDt <= 0) {
        break;
      }
    }
  }
}

class _QueuedPresentationEvent {
  _QueuedPresentationEvent({
    required this.event,
    required this.remainingDelay,
  });

  final BattlePresentationEvent event;
  double remainingDelay;
}
