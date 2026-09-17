import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rant_model.dart';
import '../services/rant_service.dart';

class FeedNotifier extends StateNotifier<AsyncValue<List<RantModel>>> {
  FeedNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  StreamSubscription? _subscription;

  void _init() {
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
  return FeedNotifier();
});
