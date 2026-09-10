import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../design/tribe_design.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final t = const TribeTheme(true);

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                leading: IconBtn(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                title: Text('Settings', style: t.display(size: 18, color: t.milk)),
              ),
              Expanded(
                child: ListView(
                  children: [
                    group('Privacy', t),
                    row(
                      icon: Icons.block,
                      label: 'Blocked accounts',
                      trailing: Icon(Icons.chevron_right, size: 16, color: t.inkFaint),
                      onTap: () => GoRouter.of(context).push('/blocked-accounts'),
                      t: t,
                    ),
                    group('Account', t),
                    row(
                      icon: Icons.logout,
                      label: 'Sign out',
                      onTap: _signOut,
                      t: t,
                    ),
                    row(
                      icon: Icons.delete_outline,
                      label: 'Delete account',
                      color: t.danger,
                      onTap: _isDeleting ? null : _confirmDeleteAccount,
                      t: t,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget group(String title, TribeTheme t) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Text(title.toUpperCase(), style: t.caption(size: 10.5)),
      );

  Widget row({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
    Widget? trailing,
    required TribeTheme t,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color ?? t.ink),
              const SizedBox(width: 13),
              Expanded(child: Text(label, style: t.body(size: 14, weight: FontWeight.w700, color: color ?? t.ink))),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      );

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) GoRouter.of(context).go('/auth');
  }

  void _confirmDeleteAccount() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => SizedBox.expand(
        child: TribeThemeScope(
          theme: const TribeTheme(true),
          child: ConfirmModal(
            title: 'Delete account?',
            body: 'This will permanently delete your account, your posts, and your replies. This cannot be undone.',
            confirmLabel: 'Delete forever',
            danger: true,
            onClose: () => Navigator.of(ctx).pop(),
            onConfirm: () async {
              setState(() => _isDeleting = true);
              try {
                await AuthService().deleteAccount();
                if (mounted) GoRouter.of(context).go('/auth');
                try {
                  await ref.read(authProvider.notifier).signOut();
                } catch (_) {}
              } catch (e) {
                if (mounted) {
                  Toast.error(context, 'Failed to delete account: $e. Please sign in again and retry.');
                }
              } finally {
                if (mounted) setState(() => _isDeleting = false);
              }
            },
          ),
        ),
      ),
    );
  }
}
