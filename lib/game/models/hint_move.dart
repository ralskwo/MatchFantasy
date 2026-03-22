import 'package:match_fantasy/game/models/grid_point.dart';

class HintMove {
  const HintMove({required this.first, required this.second});

  final GridPoint first;
  final GridPoint second;

  bool contains(GridPoint point) => point == first || point == second;
}
