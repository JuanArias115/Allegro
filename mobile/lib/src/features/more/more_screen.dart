import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Sesión'),
            subtitle: Text(auth.userLabel),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de reservas'),
            subtitle: const Text('Finalizadas y canceladas'),
            onTap: () => context.push('/history'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Modo de autenticación'),
            subtitle: Text(AppConfig.isFirebaseAuth ? 'Firebase' : 'Local (desarrollo)'),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Servidor'),
            subtitle: Text(AppConfig.apiBaseUrl),
          ),
          if (AppConfig.isFirebaseAuth)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => auth.signOut(),
            ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Allegro',
            applicationVersion: '1.0.0',
            aboutBoxChildren: [
              Text('Aplicación interna para administrar el glamping (dos domos).'),
            ],
          ),
        ],
      ),
    );
  }
}
