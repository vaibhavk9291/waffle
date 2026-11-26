import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/billing/presentation/bills_screen.dart';
import '../../features/billing/presentation/cart_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import 'supabase_service.dart';

class DateRolloverService {
  static final DateRolloverService instance = DateRolloverService._internal();
  DateRolloverService._internal();

  Timer? _timer;
  String _lastKnownDate = '';

  void start(WidgetRef ref) {
    _lastKnownDate = SupabaseService.instance.currentISTDate;

    // Check periodically for midnight transition (IST)
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      final currentDate = SupabaseService.instance.currentISTDate;
      if (currentDate != _lastKnownDate) {
        debugPrint('MIDNIGHT ROLLOVER: $_lastKnownDate -> $currentDate. Resetting daily counter.');
        _lastKnownDate = currentDate;

        // Reset current cart and invalidate today providers so sales reset to 0
        ref.read(cartProvider.notifier).clearCart();
        ref.read(todayTotalProvider.notifier).resetToZero();
        ref.read(todayBillsProvider.notifier).clearList();
        ref.invalidate(todayExpensesProvider);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
