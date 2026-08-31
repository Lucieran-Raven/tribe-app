import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/rant_model.dart';
import '../models/reply_model.dart';
import '../services/rant_service.dart';

final userProfileProvider = FutureProvider.family<UserModel, String>((ref, userId) {
  return RantService().getUser(userId);
});

final userRantsProvider = StreamProvider.family<List<RantModel>, String>((ref, userId) {
  return RantService().streamUserRants(userId);
});

final userRepliesProvider = StreamProvider.family<List<ReplyModel>, String>((ref, userId) {
  return RantService().streamUserReplies(userId);
});
