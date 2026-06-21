import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../providers.dart';

/// Pantalla de inicio de sesión (solo en modo Firebase).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signIn(_email.text, _password.text);
    } catch (e) {
      setState(
        () => _error =
            'No pudimos iniciar sesión. Revisa tu correo y contraseña.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x8,
              AppSpacing.x5,
              AppSpacing.x6,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: AppRadii.all(AppRadii.xl),
                          boxShadow: AppShadows.soft,
                        ),
                        child: SvgPicture.asset('assets/logo.svg', height: 96),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    Text(
                      'Bienvenido a Allegro',
                      textAlign: TextAlign.center,
                      style: t.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Administra tu glamping en un solo lugar',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.x7),
                    AppTextField(
                      controller: _email,
                      label: 'Correo',
                      hint: 'tucorreo@ejemplo.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Ingresa un correo válido'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    AppTextField(
                      controller: _password,
                      label: 'Contraseña',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.x4),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.x3),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.12),
                          borderRadius: AppRadii.all(AppRadii.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_rounded,
                              color: AppColors.coral,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.x6),
                    PrimaryButton(
                      label: 'Iniciar sesión',
                      icon: Icons.login_rounded,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
