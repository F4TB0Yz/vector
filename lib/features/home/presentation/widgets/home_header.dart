import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/auth/presentation/providers/auth_provider.dart';
import 'package:vector/features/auth/presentation/widgets/jt_login_dialog.dart';

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

class _StatusSelector extends ConsumerWidget {
  const _StatusSelector();

  void _handleTap(BuildContext context, WidgetRef ref, bool isAuthenticated) {
    if (!isAuthenticated) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const JtLoginDialog(),
      );
    } else {
      // Show Menu for authenticated user
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E24),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.blue),
              title: const Text('Sincronizar Datos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement Sync
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    final bool isAuthenticated = authState.when(
        data: (option) => option.isSome(),
        error: (_, __) => false,
        loading: () => false,
    );

    // Definir colores según estado
    final statusColor = isAuthenticated ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final backgroundColor = statusColor.withValues(alpha: 0.1);
    final borderColor = statusColor.withValues(alpha: 0.3);
    final text = isAuthenticated ? 'J&T LINKED' : 'OFFLINE';

    return GestureDetector(
      onTap: () => _handleTap(context, ref, isAuthenticated),
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
