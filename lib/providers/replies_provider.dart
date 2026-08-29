import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reply_model.dart';
import '../services/rant_service.dart';

final repliesProvider = StreamProvider.family<List<ReplyModel>, String>((ref, rantId) {
  return RantService().streamReplies(rantId);
});
