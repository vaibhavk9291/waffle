import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/date_rollover_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/floating_bill_bar.dart';
import '../../../core/widgets/floating_bottom_nav.dart';
import '../../billing/presentation/bill_sheet.dart';
import '../../billing/presentation/bills_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BillsScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _setupRealtimeSync();
    // Start active midnight date rollover monitor
    DateRolloverService.instance.start(ref);
  }

  void _setupRealtimeSync() {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) return;

    // Listen to bills, bill_items, and expenses realtime broadcasts
    try {
      supabase.client
          .channel('public:billing_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bills',
            callback: (payload) {
              ref.read(todayTotalProvider.notifier).refresh();
              ref.read(todayBillsProvider.notifier).refresh();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'expenses',
            callback: (payload) {
              ref.read(todayTotalProvider.notifier).refresh();
              ref.invalidate(todayExpensesProvider);
            },
          )
          .subscribe();

      // Trigger sync of queued offline transactions
      OfflineSyncService.instance.syncAll();
    } catch (e) {
      debugPrint('Realtime channel subscription error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating Bill Bar (Shows on Home or any screen when items are present)
          Positioned(
            left: 0,
            right: 0,
            bottom: 76,
            child: FloatingBillBar(
              onCheckout: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const BillSheet(),
                );
              },
            ),
          ),

          // Floating Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNav(
              currentIndex: _currentIndex,
              onTabSelected: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
