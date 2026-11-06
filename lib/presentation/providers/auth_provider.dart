import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() {
    final repo = ref.watch(authRepositoryProvider);
    final user = repo.currentAuthUser;
    if (user != null) {
      repo.loadUserProfile(user).then((profile) {
        state = AsyncValue.data(profile);
      }).catchError((e, st) {
        state = const AsyncValue.data(null);
      });
    }
    return const AsyncValue.data(null);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(AuthNotifier.new);

final currentUserProvider = Provider<UserModel?>((ref) => ref.watch(authStateProvider).asData?.value);

class MarathiNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Default language: English

  void toggle() => state = !state;
  void setMarathi(bool value) => state = value;
}

final isMarathiProvider = NotifierProvider<MarathiNotifier, bool>(MarathiNotifier.new);
