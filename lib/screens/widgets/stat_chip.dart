import 'package:flutter/material.dart';
import '/core/formatters.dart';
import '/core/constants.dart';

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.isPercent = false,
  });

  final String label;
  final double? value;
  final bool isPercent;

  @override
  Widget build(BuildContext context) {
    final isPositive = isPercent ? isUp(value) : (value ?? 0) >= 0;
    final color = isPercent
        ? (isPositive ? const Color(kGreenHex) : const Color(kRedHex))
        : Theme.of(context).colorScheme.primary;

    final text = isPercent
        ? formatPercent(value)
        : value == null
        ? '--'
        : value!.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPercent)
            Icon(
              isPositive
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
              color: color,
            ),
          if (isPercent) const SizedBox(width: 4),
          Text(
            '$label $text',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
