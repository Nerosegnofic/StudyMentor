import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/locale/locale_cubit.dart';
import 'auth_style.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/language_picker_dialog.dart';
import '../../../utils/app_version.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    // Computed here (above the Scaffold) so the keyboard is actually detected —
    // a Scaffold zeroes viewInsets.bottom for its body subtree.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return PopScope(
      canPop: canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !canGoBack) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: kAuthBackground,
        body: BlocConsumer<AuthBloc, AuthState>(
          // Only rebuild the button when loading state changes.
          buildWhen: (prev, curr) => curr is AuthLoading || prev is AuthLoading,
          // Handle side effects without setState.
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
            if (state is AuthEmailUnverified) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
            if (state is AuthError) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                _passCtl.clear();
                setState(() => _error = localizeError(state.message, AppLocalizations.of(context)));
              }
            }
          },
          builder: (context, state) {
            final loading = state is AuthLoading;
            final loc = AppLocalizations.of(context);
            return Stack(
              children: [
                Column(
                  children: [
                    AuthHeader(
                      keyboardOpen: keyboardOpen,
                      onBack: canGoBack
                          ? () => Navigator.of(context).maybePop()
                          : null,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              authErrorBanner(_error),
                              TextFormField(
                                controller: _emailCtl,
                                onChanged: (_) {
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                                decoration: authInputDecoration(
                                  label: loc.fieldEmail,
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) =>
                                    v!.contains('@') ? null : loc.loginEmailValidator,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passCtl,
                                onChanged: (_) {
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                                decoration: authInputDecoration(
                                  label: loc.fieldPassword,
                                  icon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (v) => v!.isNotEmpty ? null : loc.validatorPasswordRequired,
                              ),
                              const SizedBox(height: 24),
                              authPrimaryButton(
                                label: loc.signInTitle,
                                loading: loading,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                      LoginRequested(
                                        email: _emailCtl.text.trim(),
                                        password: _passCtl.text.trim(),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 4),
                              authTextLink(
                                text: loc.registerPromptButton,
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/register'),
                              ),
                              authTextLink(
                                text: loc.forgotPasswordButton,
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    appVersion,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: BlocBuilder<LocaleCubit, Locale>(
                    builder: (context, locale) => TextButton.icon(
                      onPressed: () => showLanguagePickerDialog(context),
                      style: TextButton.styleFrom(
                        foregroundColor: kAuthGreen,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.language_rounded, size: 16),
                      label: Text(
                        locale.languageCode == 'ar' ? 'العربية' : 'English',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
