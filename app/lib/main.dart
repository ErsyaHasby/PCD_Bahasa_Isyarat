import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/local/models/translation_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock ke portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Immersive UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Inisialisasi Hive (inheritance dari Proyek 4 — Logbook)
  await Hive.initFlutter();
  Hive.registerAdapter(TranslationEntryAdapter());
  await Hive.openBox<TranslationEntry>('translation_journal');

  runApp(const ProviderScope(child: IsyaratApp()));
}

class IsyaratApp extends ConsumerWidget {
  const IsyaratApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'IsyaratAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
