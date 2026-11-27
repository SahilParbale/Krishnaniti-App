import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'language_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends Notifier<AsyncValue<UserModel?>> {
  RealtimeChannel? _staffChannel;

  @override
  AsyncValue<UserModel?> build() {
    ref.onDispose(() {
      _cleanupStaffChannel();
    });

    final repo = ref.watch(authRepositoryProvider);
    repo.restorePersistedSession().then((user) {
      state = AsyncValue.data(user);
      if (user != null) {
        try {
          _listenToStaffChanges(user.id);
        } catch (_) {}
      }
    }).catchError((e, st) {
      state = const AsyncValue.data(null);
    });
    return const AsyncValue.loading();
  }

  void _listenToStaffChanges(String userId) {
    // Platform.environment is unsupported and throws on web; demo users have no remote staff channel
    if (kIsWeb || userId == 'demo-krishnaniti-user' || userId.startsWith('demo')) return;
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;
    } catch (_) {
      return;
    }

    _cleanupStaffChannel();
    try {
      _staffChannel = SupabaseService.instance.client
          .channel('staff-permissions-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'staff',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: userId,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord['permissions'] != null && newRecord['permissions'] is List) {
                final newPerms = (newRecord['permissions'] as List)
                    .map((e) => e.toString())
                    .toList();
                final current = state.asData?.value;
                if (current != null) {
                  state = AsyncValue.data(current.copyWith(permissions: newPerms));
                }
              }
            },
          );
      _staffChannel?.subscribe();
    } catch (_) {}
  }

  void _cleanupStaffChannel() {
    try {
      if (_staffChannel != null) {
        SupabaseService.instance.client.removeChannel(_staffChannel!);
        _staffChannel = null;
      }
    } catch (_) {}
  }

  Future<void> signIn(String email, String password, {String? role, bool isStaff = false}) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signIn(email: email, password: password, role: role, isStaff: isStaff);
      state = AsyncValue.data(user);
      try {
        _listenToStaffChanges(user.id);
      } catch (_) {}
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _cleanupStaffChannel();
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(AuthNotifier.new);

final currentUserProvider = Provider<UserModel?>((ref) => ref.watch(authStateProvider).asData?.value);

class MarathiNotifier extends Notifier<bool> {
  @override
  bool build() {
    final lang = ref.watch(appLanguageProvider);
    return lang == 'mr';
  }

  void toggle() {
    final current = ref.read(appLanguageProvider);
    ref.read(appLanguageProvider.notifier).setLanguage(current == 'mr' ? 'en' : 'mr');
  }

  void setMarathi(bool value) {
    ref.read(appLanguageProvider.notifier).setLanguage(value ? 'mr' : 'en');
  }
}

final isMarathiProvider = NotifierProvider<MarathiNotifier, bool>(MarathiNotifier.new);
