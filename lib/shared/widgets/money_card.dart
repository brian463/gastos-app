import 'package:flutter/material.dart';
import '../utils/currency.dart';

class MoneyCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;

  /// Color opcional para el número (ej: rojo cuando alerta)
  final Color? valueColor;

  const MoneyCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(radius: 22, child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(
                    Currency.format(value),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: valueColor, // ✅ aquí
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}