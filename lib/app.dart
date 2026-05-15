import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_lifecycle_provider.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Reads the GoRouter from Riverpod and wires it into MaterialApp.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/heroimage.jpg'), context);
      // Initialize sync lifecycle (wires Firestore listeners to auth state)
      ref.read(syncLifecycleProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Watch sync lifecycle to keep it alive
    ref.watch(syncLifecycleProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
