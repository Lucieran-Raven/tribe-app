import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rant_model.dart';
import '../services/rant_service.dart';
import 'auth_provider.dart';

class FeedNotifier extends StateNotifier<AsyncValue<List<RantModel>>> {
  FeedNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription? _subscription;
  StreamSubscription? _authSubscription;
  bool _hasStartedStream = false;

  void _init() {
    // Listen to authProvider for auth state changes
    _authSubscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated && !_hasStartedStream) {
        // Auth is ready, start feed stream
        _startFeedStream();
      } else if (next is AuthUnauthenticated) {
        // User signed out, clear feed
        state = const AsyncValue.data([]);
        _subscription?.cancel();
        _hasStartedStream = false;
      }
    }, fireImmediately: true);

    // Check current auth state immediately
    final authState = _ref.read(authProvider);
    if (authState is AuthAuthenticated && !_hasStartedStream) {
      _startFeedStream();
    }
  }

  void _startFeedStream() {
    if (_hasStartedStream) return;
    _hasStartedStream = true;
    
    _subscription = RantService().streamFeed().listen(
      (rants) {
        state = AsyncValue.data(rants);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void updateRant(RantModel updatedRant) {
    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final r in currentList)
        if (r.rantId == updatedRant.rantId) updatedRant else r,
    ]);
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, AsyncValue<List<RantModel>>>((ref) {
  return FeedNotifier(ref);
});
