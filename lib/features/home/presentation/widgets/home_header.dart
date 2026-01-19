import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vector/core/theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({
    super.key,
    this.userName = 'Felipe', // Default por ahora
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();
    final formattedDate =
        DateFormat('EEEE, MMMM d', 'es').format(date).toUpperCase();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                "Hola, $userName",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _StatusSelector(),
      ],
    );
  }
}

class _StatusSelector extends StatefulWidget {
  const _StatusSelector();

  @override
  State<_StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<_StatusSelector> {
  bool isOnline = true;

  void _toggleStatus() {
    setState(() {
      isOnline = !isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definir colores según estado
    final statusColor =
        isOnline ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final backgroundColor = statusColor.withValues(alpha: 0.1);
    final borderColor = statusColor.withValues(alpha: 0.3);
    final text = isOnline ? 'ONLINE' : 'OFFLINE';

    return GestureDetector(
      onTap: _toggleStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: -2,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter', // Asegurar fuente técnica
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
