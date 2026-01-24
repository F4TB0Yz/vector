import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:vector/features/auth/presentation/providers/auth_provider.dart';

class JtLoginDialog extends StatefulWidget {
  const JtLoginDialog({super.key});

  @override
  State<JtLoginDialog> createState() => _JtLoginDialogState();
}

class _JtLoginDialogState extends State<JtLoginDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Note: rememberMe logic was using getSavedCredentialsProvider which we removed from this dialog 
  // to simplify. If needed, we can init it from AuthProvider or a usecase in initState.
  // For now I'll keep the UI for rememberMe but wired to local state.
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Potentially load saved credentials here if needed via sl<GetSavedCredentials>()
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    
    await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      rememberMe: _rememberMe,
    );

    if (mounted) {
      if (authProvider.error != null) {
        showAppToast(
          context,
          authProvider.error!,
          type: ToastType.error,
        );
      } else if (authProvider.isAuthenticated) {
        Navigator.of(context).pop();
        showAppToast(context, 'Sesión iniciada', type: ToastType.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch AuthProvider for loading state
    final authProviderState = context.watch<AuthProvider>();
    final isLoading = authProviderState.isLoading;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E24), // Dark Slate
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'J&T EXPRESS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Account Input
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Usuario'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Password Input
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Contraseña'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              // Remember Me Checkbox
              Row(
                children: [
                  Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.grey),
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: const Color(0xFF00E676),
                      checkColor: Colors.black,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                  ),
                  const Text(
                    'Recordar cuenta',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676), // Neon Green
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'CONECTAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF2C2C35), // Gunmetal Grey
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: Color(0xFF00E676), width: 1),
      ),
    );
  }
}
