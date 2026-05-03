import 'dart:ui';

class ProjectilePathGeometry {
  const ProjectilePathGeometry._();

  static Offset pointAt({
    required Offset start,
    required Offset end,
    required double progress,
    required double fieldWidth,
    required double travelHeight,
    required double arcHeight,
    required double arcBias,
  }) {
    final (Offset, Offset) controls = _controlsFor(
      start: start,
      end: end,
      fieldWidth: fieldWidth,
      travelHeight: travelHeight,
      arcHeight: arcHeight,
      arcBias: arcBias,
    );
    return _cubicPoint(
      start,
      controls.$1,
      controls.$2,
      end,
      progress.clamp(0.0, 1.0),
    );
  }

  static (Offset, Offset) _controlsFor({
    required Offset start,
    required Offset end,
    required double fieldWidth,
    required double travelHeight,
    required double arcHeight,
    required double arcBias,
  }) {
    final double effectiveBias = arcBias.abs() < 0.02
        ? (end.dx >= start.dx ? 0.18 : -0.18)
        : arcBias;
    final double biasDirection = effectiveBias.sign == 0 ? 1.0 : effectiveBias.sign;
    final double biasStrength = effectiveBias.abs().clamp(0.12, 0.4);

    final double firstSideLead =
        fieldWidth * (0.24 + (biasStrength * 0.7)) * biasDirection;
    final double secondSideLead =
        fieldWidth * (0.10 + (biasStrength * 0.45)) * biasDirection;
    final double firstLift = -travelHeight * (0.005 + (arcHeight * 0.022));
    final double secondLift = -travelHeight * (0.025 + (arcHeight * 0.1));

    return (
      start + Offset(firstSideLead, firstLift),
      end + Offset(secondSideLead, secondLift),
    );
  }

  static Offset _cubicPoint(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final double mt = 1 - t;
    final double a = mt * mt * mt;
    final double b = 3 * mt * mt * t;
    final double c = 3 * mt * t * t;
    final double d = t * t * t;
    return Offset(
      (p0.dx * a) + (p1.dx * b) + (p2.dx * c) + (p3.dx * d),
      (p0.dy * a) + (p1.dy * b) + (p2.dy * c) + (p3.dy * d),
    );
  }
}
