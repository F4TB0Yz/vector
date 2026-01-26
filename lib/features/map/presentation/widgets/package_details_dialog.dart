import 'package:flutter/material.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:url_launcher/url_launcher.dart';

class PackageDetailsDialog extends StatelessWidget {
  final StopEntity stop;

  const PackageDetailsDialog({super.key, required this.stop});

  Color _getStatusColor(PackageStatus status) {
    switch (status) {
      case PackageStatus.pending:
        return Colors.orange;
      case PackageStatus.delivered:
        return Colors.green;
      case PackageStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(PackageStatus status) {
    switch (status) {
      case PackageStatus.pending:
        return 'PENDIENTE';
      case PackageStatus.delivered:
        return 'ENTREGADO';
      case PackageStatus.failed:
        return 'FALLIDO';
      default:
        return 'DESCONOCIDO';
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, {String? message}) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final String encodedMsg = message != null ? Uri.encodeComponent(message) : '';
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showMessageTemplates(BuildContext context, String phoneNumber) {
    final List<Map<String, String>> templates = [
      {
        'title': 'Próximo a entrega',
        'message': '🚚 Hola, soy tu repartidor de Vector. Estoy cerca de tu ubicación para entregar tu paquete. ¿Te encuentras disponible?',
      },
      {
        'title': 'Paquete entregado',
        'message': '✅ Tu paquete ha sido entregado exitosamente. ¡Gracias por confiar en nosotros!',
      },
      {
        'title': 'Entrega fallida',
        'message': '❌ Hola, intenté entregar tu paquete pero no hubo respuesta. Por favor indícame si puedo pasar más tarde o si prefieres reprogramar.',
      },
      {
        'title': 'Reprogramada',
        'message': '📅 Hola, informamos que tu entrega ha sido reprogramada para una nueva fecha. Nos pondremos en contacto pronto.',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'PLANTILLAS DE MENSAJE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...templates.map((template) => ListTile(
                title: Text(
                  template['title']!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                trailing: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 20),
                onTap: () {
                  Navigator.pop(context);
                  _openWhatsApp(phoneNumber, message: template['message']);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final package = stop.package;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white10, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Stop Order and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Parada #${stop.stopOrder}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(package.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(package.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(package.status),
                    style: TextStyle(
                      color: _getStatusColor(package.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Receiver Name
            const Text(
              'RECEPTOR',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package.receiverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Address
            const Text(
              'DIRECCIÓN',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package.address,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Notes (if any)
            if (package.notes != null && package.notes!.isNotEmpty) ...[
              const Text(
                'NOTAS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                  border: const Border(
                    left: BorderSide(
                      color: Colors.orangeAccent,
                      width: 4,
                    ),
                  ),
                ),
                child: Text(
                  package.notes!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Phone
            const Text(
              'TELÉFONO',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package.phone,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone,
                    label: 'Llamar',
                    color: Colors.blue,
                    onTap: () => _makeCall(package.phone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => _openWhatsApp(package.phone),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                icon: Icons.message_outlined,
                label: 'Plantillas de Mensaje',
                color: Colors.orangeAccent,
                onTap: () => _showMessageTemplates(context, package.phone),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'CERRAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
