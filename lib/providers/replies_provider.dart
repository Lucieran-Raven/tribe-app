import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reply_model.dart';
import '../services/rant_service.dart';

class RepliesNotifier extends StateNotifier<AsyncValue<List<ReplyModel>>> {
  RepliesNotifier(this.rantId) : super(const AsyncValue.loading()) {
    _init();
  }

  final String rantId;
  StreamSubscription? _subscription;

  void _init() {
    _subscription = RantService().streamReplies(rantId).listen(
      (replies) {
        state = AsyncValue.data(replies);
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

  void updateReply(ReplyModel updatedReply) {
    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final r in currentList)
        if (r.replyId == updatedReply.replyId) updatedReply else r,
    ]);
  }
}

final repliesProvider = StreamProvider.family<List<ReplyModel>, String>((ref, rantId) {
  return RantService().streamReplies(rantId);
});

final repliesStateProvider = StateProvider.family<AsyncValue<List<ReplyModel>>, String>((ref, rantId) {
  return AsyncValue.loading();
});
