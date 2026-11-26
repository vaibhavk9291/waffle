import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/user_profile.dart';

class AuthStateData {
  final bool isLoading;
  final User? user;
  final UserProfile? profile;
  final String? errorMessage;

  const AuthStateData({
    this.isLoading = false,
    this.user,
    this.profile,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthStateData copyWith({
    bool? isLoading,
    User? user,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthStateData> {
  AuthNotifier() : super(const AuthStateData()) {
    _init();
  }

  final SupabaseService _supabase = SupabaseService.instance;

  void _init() {
    if (!_supabase.isInitialized) return;

    final current = _supabase.currentUser;
    if (current != null) {
      state = state.copyWith(user: current);
      _fetchProfile(current.id);
    }

    _supabase.authStateChanges.listen((event) {
      final u = event.session?.user;
      if (u != null) {
        state = state.copyWith(user: u);
        _fetchProfile(u.id);
      } else {
        state = const AuthStateData();
      }
    });
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final res = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        final profile = UserProfile.fromJson(res);
        state = state.copyWith(profile: profile);
      } else {
        // Default staff profile fallback
        state = state.copyWith(
          profile: UserProfile(id: userId, displayName: 'Counter Staff', role: 'staff'),
        );
      }
    } catch (e) {
      debugPrint('Profile fetch fallback: $e');
      state = state.copyWith(
        profile: UserProfile(id: userId, displayName: 'Counter Staff', role: 'staff'),
      );
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, user: res.user);
      if (res.user != null) {
        await _fetchProfile(res.user!.id);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AuthException ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    if (_supabase.isInitialized) {
      await _supabase.client.auth.signOut();
    }
    state = const AuthStateData();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  return AuthNotifier();
});
