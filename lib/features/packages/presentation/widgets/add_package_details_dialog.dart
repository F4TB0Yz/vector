import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';

class AddPackageDetailsDialog extends ConsumerStatefulWidget {
  final String trackingCode;
  final JTPackage? prefillData;

  const AddPackageDetailsDialog({
    super.key,
    required this.trackingCode,
    this.prefillData,
  });

  @override
  ConsumerState<AddPackageDetailsDialog> createState() =>
      _AddPackageDetailsDialogState();
}

class _AddPackageDetailsDialogState
    extends ConsumerState<AddPackageDetailsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.prefillData?.receiverName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.prefillData?.address ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.prefillData?.phone ?? '',
    );
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

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final result = {
        'code': widget.trackingCode,
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'notes': _notesController.text,
      };
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: AppColors.primary.withAlpha(50)),
      ),
      title: Row(
        children: [
          const Icon(
            LucideIcons.packagePlus,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('Añadir Paquete', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa los detalles para el paquete ${widget.trackingCode}',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                labelText: 'Nombre del Cliente',
                icon: LucideIcons.user,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                labelText: 'Dirección de Entrega',
                icon: LucideIcons.mapPin,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                labelText: 'Número de Teléfono',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                labelText: 'Notas Adicionales (Opcional)',
                icon: LucideIcons.fileText,
                isOptional: true,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: _onSave,
          icon: const Icon(LucideIcons.check, size: 16),
          label: const Text('Guardar Parada'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isOptional = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF9AB0BC), size: 20),
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: const Color(0x32000000),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }
}
