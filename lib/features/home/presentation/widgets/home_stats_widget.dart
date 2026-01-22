import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/home/presentation/widgets/price_input_dialog.dart';

class HomeStatsWidget extends StatefulWidget {
  final int deliveredCount;

  const HomeStatsWidget({
    super.key,
    required this.deliveredCount,
  });

  @override
  State<HomeStatsWidget> createState() => _HomeStatsWidgetState();
}

class _HomeStatsWidgetState extends State<HomeStatsWidget> {
  double _pricePerPackage = 0;

  void _showPriceDialog() {
    showDialog(
      context: context,
      builder: (_) => PriceInputDialog(
        onPriceConfirmed: (value) {
          setState(() {
            _pricePerPackage = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final totalEarnings = _pricePerPackage * widget.deliveredCount;
    final formattedEarnings = currencyFormat.format(totalEarnings);

    return Row(
      children: [
        // Earnings Card (Interactive)
        Expanded(
          child: CustomCard(
            onTap: _showPriceDialog,
            padding: const EdgeInsets.all(16),
            isDarkBackground: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    if (_pricePerPackage > 0)
                      const Text(
                        '+CO',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formattedEarnings,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GANANCIAS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Time Card - Isolated to prevent rebuilding the entire widget
        const Expanded(
          child: _RouteTimeCard(),
        ),
      ],
    );
  }
}

/// Isolated widget to prevent Timer rebuilds from affecting parent
class _RouteTimeCard extends StatefulWidget {
  const _RouteTimeCard();

  @override
  State<_RouteTimeCard> createState() => _RouteTimeCardState();
}

class _RouteTimeCardState extends State<_RouteTimeCard> {
  Timer? _timer;
  Duration _elapsed = const Duration(hours: 1, minutes: 24);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');

    return CustomCard(
      padding: const EdgeInsets.all(16),
      isDarkBackground: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(height: 12),
          Text(
            '$hours h $minutes m',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TIEMPO RUTA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
