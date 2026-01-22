import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:vector/core/theme/app_colors.dart';
import '../../../../core/utils/device_utils.dart';
import '../providers/auth_provider.dart';

class JtLoginDialog extends ConsumerStatefulWidget {
  const JtLoginDialog({super.key});

  @override
  ConsumerState<JtLoginDialog> createState() => _JtLoginDialogState();
}

class _JtLoginDialogState extends ConsumerState<JtLoginDialog> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    // Wait for the provider to be ready (safe in initState usually, but let's be safe)
    // Actually, we can read provider directly in initState if we don't watch.
    
    // We need to wait a bit or use addPostFrameCallback because we are accessing context/ref 
    // but ref is available in ConsumerState.
    
    // Using Future.microtask or just async execution
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       final getSavedCreds = ref.read(getSavedCredentialsProvider);
       final creds = await getSavedCreds();
       
       if (creds != null && mounted) {
         setState(() {
           _accountController.text = creds['account'] ?? '';
           _passwordController.text = creds['password'] ?? '';
           _rememberMe = true;
         });
       }
    });
  }

  Future<void> _loadDeviceData() async {
    // This will fetch and print device data with colors in console
    await DeviceUtils.getJtDeviceData();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Trigger login
    await ref.read(authProvider.notifier).login(
      _accountController.text.trim(),
      _passwordController.text.trim(),
      rememberMe: _rememberMe,
    );

    // Watch for state changes is tricky in strictly async flow event handler, 
    // but we can check the *new* state via ref.read or wait for the future to complete if the notifier returns it.
    // However, the notifier method returns Future<void> and updates state internally.
    // The build() method will react to state changes.
    // But we want to close the dialog on success.
    
    // Better approach: listen to provider in build/listener or check state after await if notifier waits.
    // Our notifier implementation awaits the usecase, so after await, state is updated.
    
    if (!mounted) return;
    
    final state = ref.read(authProvider);
    
    if (state is AsyncData<Option<dynamic>>) {
       final userOption = state.value;
       if (userOption != null && userOption.isSome()) {
         Navigator.of(context).pop();
       }
    }
    
    if (state is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.error.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    // Listen for success to close dialog automatically? 
    // Doing it in _handleLogin is okay for modal dialogs usually.
    
    return Dialog(
      backgroundColor: const Color(0xFF1E1E24), // Dark Slate
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.border)),
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
                controller: _accountController,
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
              
                // Action Button
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
                      'Recordar cuenta', // TODO: localize
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF00E676), width: 1),
      ),
    );
  }
}
