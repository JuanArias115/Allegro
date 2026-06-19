import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

class AllegroApp extends ConsumerWidget {
  const AllegroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Allegro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Respeta la fuente del sistema pero la acota: con "letra grande" la app
        // crece un poco sin deformar. Usamos un factor lineal acotado (no
        // textScaler.clamp encadenado, que choca con el clamp interno de los
        // diálogos de Material como el selector de fecha).
        final mq = MediaQuery.of(context);
        final factor = (mq.textScaler.scale(100) / 100).clamp(1.0, 1.3);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(factor)),
          child: child!,
        );
      },
    );
  }
}
