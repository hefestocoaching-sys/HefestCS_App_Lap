import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorText = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = _mapAuthError(e));
    } catch (_) {
      setState(
        () => _errorText = 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorText = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = _mapAuthError(e));
    } catch (_) {
      setState(
        () => _errorText = 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Credenciales incorrectas.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      default:
        return 'No se pudo iniciar sesión. (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determinar si es pantalla compacta basado en restricciones de layout
            // Evitar hardcodear valores de resolución
            final isCompact = constraints.maxWidth < 900;

            return Stack(
              children: [
                _PremiumBackground(isCompact: isCompact),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.9,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: SingleChildScrollView(
                        child: _GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Header(isCompact: isCompact),
                                const SizedBox(height: 18),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _LabeledField(
                                        label: 'Correo',
                                        child: TextFormField(
                                          controller: _emailCtrl,
                                          enabled: !_loading,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autofillHints: const [
                                            AutofillHints.username,
                                            AutofillHints.email,
                                          ],
                                          textInputAction: TextInputAction.next,
                                          decoration: hcsDecoration(
                                            context,
                                            hintText: 'correo@dominio.com',
                                          ),
                                          validator: (v) {
                                            final s = (v ?? '').trim();
                                            if (s.isEmpty) {
                                              return 'Ingresa tu correo.';
                                            }
                                            if (!s.contains('@') ||
                                                !s.contains('.')) {
                                              return 'Correo inválido.';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _LabeledField(
                                        label: 'Contraseña',
                                        child: TextFormField(
                                          controller: _passCtrl,
                                          enabled: !_loading,
                                          obscureText: _obscure,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _signIn(),
                                          decoration: hcsDecoration(
                                            context,
                                            hintText: '••••••••',
                                            suffixIcon: IconButton(
                                              onPressed: _loading
                                                  ? null
                                                  : () => setState(
                                                      () =>
                                                          _obscure = !_obscure,
                                                    ),
                                              icon: Icon(
                                                _obscure
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                              ),
                                              tooltip: _obscure
                                                  ? 'Mostrar'
                                                  : 'Ocultar',
                                            ),
                                          ),
                                          validator: (v) {
                                            final s = (v ?? '').trim();
                                            if (s.isEmpty) {
                                              return 'Ingresa tu contraseña.';
                                            }
                                            if (s.length < 6) {
                                              return 'Debe tener al menos 6 caracteres.';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (_errorText != null) ...[
                                  _InlineError(text: _errorText!),
                                  const SizedBox(height: 10),
                                ],
                                SizedBox(
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _signIn,
                                    child: _loading
                                        ? const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                              SizedBox(width: 10),
                                              Text('Verificando…'),
                                            ],
                                          )
                                        : const Text('Iniciar sesión'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '¿Nuevo coach?',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : _createAccount,
                                      child: const Text('Crear cuenta'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isCompact;
  const _Header({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.science_outlined),
            ),
            const SizedBox(width: 12),
            Text(
              'Acceso profesional',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Gestión clínica de nutrición y entrenamiento.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String text;
  const _InlineError({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.red.withValues(alpha: 0.08),
        border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: Colors.red.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.black.withValues(alpha: 0.75),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  final bool isCompact;
  const _PremiumBackground({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F7FB), Color(0xFFEDEFF7)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -120,
            top: -120,
            child: _Blob(size: 320, opacity: 0.18),
          ),
          const Positioned(
            right: -140,
            bottom: -140,
            child: _Blob(size: 360, opacity: 0.14),
          ),
          if (!isCompact)
            Positioned(
              left: 40,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HCS Coach',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Plataforma profesional basada en evidencia.\nOffline-first. Trazabilidad clínica. Motor científico.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.35,
                        color: Colors.black.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _MiniPill(text: 'Offline-first'),
                    const SizedBox(height: 8),
                    const _MiniPill(text: 'Motor de entrenamiento'),
                    const SizedBox(height: 8),
                    const _MiniPill(text: 'Historial por fecha'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  const _Blob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.black.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  const _MiniPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}
