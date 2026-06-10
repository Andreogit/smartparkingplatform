import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Score color palette (best → worst after top 3).
abstract final class ScorePalette {
  static const vibrantGreen = Color(0xFF44CE1B);
  static const yellowGreen = Color(0xFFBBDB44);
  static const goldenYellow = Color(0xFFF7E379);
  static const orangeRed = Color(0xFFF2A134);
}

/// Colors + label for a parking recommendation score (lower = better).
class ParkingScoreVisual {
  const ParkingScoreVisual({
    required this.accent,
    required this.backgroundColor,
    required this.borderColor,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.label,
  });

  final Color accent;
  final Color backgroundColor;
  final Color borderColor;
  /// Tinted fill for list score badges.
  final Color badgeColor;
  /// Readable label on [badgeColor], distinct from card body text.
  final Color badgeTextColor;
  final String label;
}

/// Darkens the score hue so white badge labels stay readable.
Color _listBadgeBackground(Color scoreColor) {
  final hsl = HSLColor.fromColor(scoreColor);
  final targetLightness = hsl.lightness > 0.62
      ? 0.5
      : hsl.lightness > 0.5
          ? 0.44
          : (hsl.lightness * 0.9).clamp(0.38, 0.48);
  return hsl
      .withLightness(targetLightness)
      .withSaturation(hsl.saturation.clamp(0.55, 1.0))
      .toColor();
}

/// Top 3 ranked options are green; the rest use yellow-green → golden → orange-red.
ParkingScoreVisual resolveParkingScoreVisual({
  required int rankIndex,
  required int totalCount,
  required L10n l10n,
  bool forList = false,
}) {
  if (rankIndex < 3) {
    return _fromPalette(
      border: ScorePalette.vibrantGreen,
      accent: const Color(0xFF2A9414),
      label: l10n.scoreBest,
      bgOpacity: 0.12,
      forList: forList,
    );
  }

  final remaining = totalCount - 3;
  if (remaining <= 0) {
    return _fromPalette(
      border: ScorePalette.vibrantGreen,
      accent: const Color(0xFF2A9414),
      label: l10n.scoreBest,
      bgOpacity: 0.12,
      forList: forList,
    );
  }

  final slot = rankIndex - 3;
  final bandSize = (remaining / 3).ceil();

  if (slot < bandSize) {
    return _fromPalette(
      border: ScorePalette.yellowGreen,
      accent: const Color(0xFF5F7018),
      label: l10n.scoreGood,
      bgOpacity: 0.14,
      forList: forList,
    );
  }
  if (slot < bandSize * 2) {
    return _fromPalette(
      border: ScorePalette.goldenYellow,
      accent: const Color(0xFF9A8530),
      label: l10n.scoreWorse,
      bgOpacity: 0.18,
      forList: forList,
    );
  }
  return _fromPalette(
    border: ScorePalette.orangeRed,
    accent: const Color(0xFFC07820),
    label: l10n.scoreWorst,
    bgOpacity: 0.14,
    forList: forList,
  );
}

ParkingScoreVisual _fromPalette({
  required Color border,
  required Color accent,
  required String label,
  required double bgOpacity,
  bool forList = false,
}) {
  if (forList) {
    return ParkingScoreVisual(
      accent: accent,
      backgroundColor: Color.lerp(Colors.white, border, 0.07) ?? Colors.white,
      borderColor: border.withOpacity(0.32),
      badgeColor: _listBadgeBackground(border),
      badgeTextColor: Colors.white,
      label: label,
    );
  }

  return ParkingScoreVisual(
    accent: accent,
    backgroundColor: border.withOpacity(bgOpacity),
    borderColor: border,
    badgeColor: border,
    badgeTextColor: accent,
    label: label,
  );
}

/// Score value + colored quality badge (used under parking title).
class ParkingScoreRow extends StatelessWidget {
  const ParkingScoreRow({
    super.key,
    required this.score,
    required this.rankIndex,
    required this.totalCount,
    required this.l10n,
    this.compact = false,
  });

  final double score;
  final int rankIndex;
  final int totalCount;
  final L10n l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visual = resolveParkingScoreVisual(
      rankIndex: rankIndex,
      totalCount: totalCount,
      l10n: l10n,
      forList: compact,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.scoreLabel(score),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: compact ? 12 : null,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        _ScoreBadge(visual: visual, compact: compact),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.visual, this.compact = false});

  final ParkingScoreVisual visual;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final badgeTextStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
            height: 1.1,
            color: visual.badgeTextColor,
            shadows: const [
              Shadow(
                color: Color(0x33000000),
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: visual.badgeColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          visual.label,
          style: badgeTextStyle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: visual.borderColor,
          width: 2,
        ),
      ),
      child: Text(
        visual.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: visual.accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
