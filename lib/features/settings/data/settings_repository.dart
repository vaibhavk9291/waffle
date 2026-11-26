import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/shop_settings.dart';

class SettingsRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<ShopSettings> getSettings() async {
    if (!_supabase.isInitialized) return ShopSettings.defaultSettings();
    try {
      final res = await _supabase.client
          .from('shop_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (res != null) {
        return ShopSettings.fromJson(res);
      }
      return ShopSettings.defaultSettings();
    } catch (e) {
      debugPrint('getSettings error: $e');
      return ShopSettings.defaultSettings();
    }
  }

  Future<void> updateSettings(ShopSettings settings) async {
    if (!_supabase.isInitialized) return;
    try {
      await _supabase.client
          .from('shop_settings')
          .update(settings.toJson())
          .eq('id', 1);
    } catch (e) {
      debugPrint('updateSettings error: $e');
      rethrow;
    }
  }
}
