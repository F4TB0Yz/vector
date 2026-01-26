import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:vector/features/map/presentation/providers/map_state.dart';

import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class ConfirmAddStopDialog extends StatefulWidget {
  final StopCreationRequest request;

  const ConfirmAddStopDialog({super.key, required this.request});

  @override
  State<ConfirmAddStopDialog> createState() => _ConfirmAddStopDialogState();
}

class _ConfirmAddStopDialogState extends State<ConfirmAddStopDialog> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Watch the provider to rebuild when geocoding finishes
    final currentRequest = context.select<MapProvider, StopCreationRequest?>(
      (provider) => provider.state.stopCreationRequest,
    );

    final displayRequest = currentRequest ?? widget.request;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Nueva Parada',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Content
                      if (displayRequest.isGeocoding && _addressController.text.isEmpty)
                        _buildGeocodingIndicator()
                      else
                        _buildFormFields(textTheme),
                      const SizedBox(height: 32),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel button
                          TextButton(
                            onPressed: () {
                              context.read<MapProvider>().cancelStopCreation();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Confirm button
                          _buildConfirmButton(displayRequest),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(TextTheme textTheme) {
    final currentRequest = context.watch<MapProvider>().state.stopCreationRequest;
    final detectedAddress = currentRequest?.suggestedAddress ?? 'Obteniendo ubicación...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detected Location (Internal)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.mapPin, color: AppColors.accent.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación detectada (Interna)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      detectedAddress,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _nameController,
          label: 'Nombre del Cliente',
          icon: LucideIcons.user,
          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Dirección del Paquete (la que se mostrará)',
          icon: LucideIcons.package,
          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Teléfono',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _notesController,
          label: 'Notas',
          icon: LucideIcons.fileText,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.accent.withValues(alpha: 0.7), size: 18),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.accent, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(StopCreationRequest displayRequest) {
    final isReady = !displayRequest.isGeocoding || _addressController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: !isReady
            ? null
            : const LinearGradient(
                colors: [AppColors.accent, Color(0xFF00CC5E)],
              ),
        boxShadow: !isReady
            ? null
            : [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: !isReady
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final routesProvider = context.read<RoutesProvider>();
                    context.read<MapProvider>().confirmStopCreation(
                          routesProvider,
                          customerName: _nameController.text,
                          address: _addressController.text,
                          phone: _phoneController.text,
                          notes: _notesController.text,
                        );
                  }
                },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            child: Text(
              'Confirmar',
              style: TextStyle(
                color: !isReady ? Colors.grey : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeocodingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Obteniendo dirección...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressContent(
    TextTheme textTheme,
    StopCreationRequest displayRequest,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Desea crear una nueva parada en esta ubicación?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayRequest.suggestedAddress ??
                      'No se pudo obtener la dirección.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
