import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/auth_models.dart';
import '../../providers.dart';
import '../../services/api_error_message.dart';
import '../../widgets/minimal_field.dart';
import '../auth/login_screen.dart';
import 'privacy_policy_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const route = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<UserProfile> _future;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiServiceProvider).me();
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submitPasswordChange(L10n t) async {
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.passwordsDoNotMatch)),
      );
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await ref.read(apiServiceProvider).changePassword(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
          );
      if (!mounted) {
        return;
      }
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.passwordChanged)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e)), duration: const Duration(seconds: 6)),
      );
    } finally {
      if (mounted) {
        setState(() => _changingPassword = false);
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(secureStorageProvider).delete(key: 'access_token');
    ref.read(authTokenProvider.notifier).state = null;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.route, (_) => false);
  }

  String _formatJoined(DateTime dt, L10n t) {
    final locale = t.isUk ? 'uk_UA' : 'en_US';
    return DateFormat.yMMMMd(locale).add_Hm().format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.l10n;
    final scheme = Theme.of(context).colorScheme;
    final localeCode = ref.watch(localeCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: t.logout,
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(t.profileLoadError(snapshot.error!)));
          }

          final u = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.person_outline, size: 36, color: scheme.primary),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.language,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<String>(
                                segments: [
                                  ButtonSegment(value: 'uk', label: Text(t.ukrainian)),
                                  ButtonSegment(value: 'en', label: Text(t.english)),
                                ],
                                selected: {localeCode},
                                onSelectionChanged: (selected) {
                                  final code = selected.first;
                                  ref.read(localeCodeProvider.notifier).setLocale(code);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t.account,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ReadOnlyField(label: t.email, value: u.email),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t.changePassword,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              MinimalField(
                                controller: _currentPassword,
                                label: t.currentPassword,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                              MinimalField(
                                controller: _newPassword,
                                label: t.newPassword,
                                obscureText: true,
                                helperText: t.passwordHint,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                              MinimalField(
                                controller: _confirmPassword,
                                label: t.confirmNewPassword,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!_changingPassword) {
                                    _submitPasswordChange(t);
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _changingPassword ? null : () => _submitPasswordChange(t),
                                child: Text(_changingPassword ? t.savingPassword : t.savePassword),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => showPrivacyPolicyDialog(context, t),
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: Text(t.privacyPolicy),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  border: Border(top: BorderSide(color: scheme.outlineVariant.withOpacity(0.6))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReadOnlyField(label: t.userId, value: u.id),
                    const SizedBox(height: 12),
                    ReadOnlyField(label: t.joinedAt, value: _formatJoined(u.createdAt, t)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
