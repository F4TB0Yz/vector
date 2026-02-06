import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/home/presentation/widgets/price_input_dialog.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class HomeStatsWidget extends StatefulWidget {
  const HomeStatsWidget({super.key});

  @override
  State<HomeStatsWidget> createState() => _HomeStatsWidgetState();
}

class _HomeStatsWidgetState extends State<HomeStatsWidget> {
  double _pricePerPackage = 0;
  late NumberFormat currencyFormat;

  @override
  void initState() {
    super.initState();
    currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
  }

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
    final selectedRoute = context.select<RoutesProvider, RouteEntity?>(
      (p) => p.selectedRoute,
    );
    final deliveredCount =
        selectedRoute?.stops
            .where((stop) => stop.status == PackageStatus.delivered)
            .length ??
        0;
    final totalEarnings = _pricePerPackage * deliveredCount;
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
        Expanded(child: _RouteTimeCard(startTime: selectedRoute?.createdAt)),
      ],
    );
  }
}

/// Isolated widget to prevent Timer rebuilds from affecting parent
class _RouteTimeCard extends StatefulWidget {
  final DateTime? startTime;

  const _RouteTimeCard({this.startTime});

  @override
  State<_RouteTimeCard> createState() => _RouteTimeCardState();
}

class _RouteTimeCardState extends State<_RouteTimeCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  @override
  void didUpdateWidget(_RouteTimeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) {
      _scheduleTick();
    }
  }

  void _scheduleTick() {
    _timer?.cancel();
    if (widget.startTime == null) return;

    final now = DateTime.now();
    final duration = now.difference(widget.startTime!);

    int nextTickSeconds;
    if (duration.inMinutes < 1) {
      // Menos de 1 minuto: Actualizar cada segundo
      nextTickSeconds = 1;
    } else {
      // Más de 1 minuto: Alinear al siguiente minuto
      // Ejemplo: 1m 15s. Faltan 45s para 2m 00s.
      nextTickSeconds = 60 - (duration.inSeconds % 60);
      if (nextTickSeconds <= 0) nextTickSeconds = 60;
    }

    _timer = Timer(Duration(seconds: nextTickSeconds), () {
      if (mounted) {
        setState(() {}); // Rebuild to update UI
        _scheduleTick(); // Schedule next
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
    final duration = widget.startTime != null
        ? DateTime.now().difference(widget.startTime!)
        : Duration.zero;

    String timeText;
    String labelText;

    if (duration.inMinutes < 1) {
      // Menos de 1 minuto: Mostrar segundos
      final seconds = duration.inSeconds.toString().padLeft(2, '0');
      timeText = '$seconds s';
      labelText = 'TIEMPO INICIAL';
    } else {
      // Más de 1 minuto: Mostrar Horas y Minutos
      final hours = duration.inHours.toString().padLeft(2, '0');
      final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
      timeText = '$hours h $minutes m';
      labelText = 'TIEMPO RUTA';
    }

    // Si no hay ruta, mostrar estado por defecto
    if (widget.startTime == null) {
      timeText = '-- h -- m';
    }

    return RepaintBoundary(
      child: CustomCard(
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
              timeText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labelText,
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
    );
  }
}
