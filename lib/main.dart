import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if credentials are provided
  await SupabaseService.instance.initialize();

  // Initialize Offline Queue
  await OfflineSyncService.instance.init();

  runApp(
    const ProviderScope(
      child: ShrimantApp(),
    ),
  );
}

class ShrimantApp extends ConsumerWidget {
  const ShrimantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _resolveInitialScreen(authState),
    );
  }

  Widget _resolveInitialScreen(AuthStateData authState) {
    // If Supabase is not yet configured or user is authenticated, allow entry to MainShell
    if (!AppConfig.isConfigured || authState.isAuthenticated) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}
