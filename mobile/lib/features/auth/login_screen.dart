import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../../providers/favorites_provider.dart';
import '../../services/api_error_message.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/minimal_field.dart';
import '../map/map_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.login(email: _email.text.trim(), password: _password.text);
      await ref.read(secureStorageProvider).write(key: 'access_token', value: res.accessToken);
      ref.read(authTokenProvider.notifier).state = res.accessToken;
      await ref.read(favoriteParkingIdsProvider.notifier).reload();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(MapScreen.route);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e)), duration: const Duration(seconds: 6)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AuthShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(title: t.appTitle, subtitle: t.signInToContinue),
            const SizedBox(height: 36),
            MinimalField(
              controller: _email,
              label: t.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            MinimalField(
              controller: _password,
              label: t.password,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_busy) {
                  _submit();
                }
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? t.signingIn : t.signIn),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
              onPressed: () => Navigator.of(context).pushNamed(RegisterScreen.route),
              child: Text(t.createAccount),
            ),
          ],
        ),
      ),
    );
  }
}
