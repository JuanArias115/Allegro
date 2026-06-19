import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/feedback.dart';
import '../../providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final label = auth.userLabel;
    final initials = _initials(label);

    return AppScaffold(
      header: const AppHeader(title: 'Más'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x2, AppSpacing.x5, 120),
        children: [
          // Perfil
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(initials,
                      style: const TextStyle(color: AppColors.forest, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text('Allegro · Glamping', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _GroupLabel('Administración'),
          _Group(children: [
            _SettingTile(
              icon: Icons.local_cafe_rounded,
              color: AppColors.coral,
              title: 'Productos',
              subtitle: 'Catálogo de productos y servicios',
              onTap: () => context.push('/products'),
            ),
            _SettingTile(
              icon: Icons.history_rounded,
              color: AppColors.violet,
              title: 'Historial',
              subtitle: 'Reservas finalizadas y canceladas',
              onTap: () => context.push('/history'),
            ),
          ]),

          _GroupLabel('Conexión'),
          _Group(children: [
            _SettingTile(
              icon: Icons.verified_user_rounded,
              color: AppColors.blue,
              title: 'Autenticación',
              value: AppConfig.isFirebaseAuth ? 'Firebase' : 'Local',
            ),
            if (!AppConfig.isFirebaseAuth)
              _SettingTile(
                icon: Icons.dns_rounded,
                color: AppColors.yellow,
                title: 'Servidor (desarrollo)',
                value: AppConfig.apiBaseUrl,
              ),
          ]),

          _GroupLabel('Aplicación'),
          _Group(children: [
            _SettingTile(
              icon: Icons.info_rounded,
              color: AppColors.forest,
              title: 'Acerca de Allegro',
              value: 'v1.0.0',
              onTap: () => _about(context),
            ),
          ]),

          if (AppConfig.isFirebaseAuth) ...[
            const SizedBox(height: AppSpacing.x4),
            _Group(children: [
              _SettingTile(
                icon: Icons.logout_rounded,
                color: AppColors.coral,
                title: 'Cerrar sesión',
                titleColor: AppColors.coral,
                onTap: () async {
                  final ok = await showConfirmationSheet(
                    context,
                    title: 'Cerrar sesión',
                    message: '¿Quieres salir de tu cuenta?',
                    confirmLabel: 'Cerrar sesión',
                    icon: Icons.logout_rounded,
                    accent: AppColors.coral,
                  );
                  if (ok) await auth.signOut();
                },
              ),
            ]),
          ],
        ],
      ),
    );
  }

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
  }

  void _about(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.x5, 0, AppSpacing.x5, AppSpacing.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CategoryIcon(icon: Icons.cabin_rounded, color: AppColors.forest, size: 64),
              const SizedBox(height: AppSpacing.x3),
              Text('Allegro', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Administración del glamping · 2 domos',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('Versión 1.0.0', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, AppSpacing.x6, 4, AppSpacing.x2),
        child: Text(text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 0.4)),
      );
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.all(AppRadii.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 64, color: scheme.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? value;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.value,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.all(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CategoryIcon(icon: icon, color: color, size: 40),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: titleColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(value!,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              if (onTap != null && value == null)
                Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
