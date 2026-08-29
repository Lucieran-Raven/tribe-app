import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rant_model.dart';
import '../services/rant_service.dart';

final feedProvider = StreamProvider<List<RantModel>>((ref) {
  return RantService().streamFeed();
});
