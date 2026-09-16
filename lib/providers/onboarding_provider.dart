import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/affiliation_model.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';
import '../utils/affiliation_sort.dart';
import 'auth_provider.dart';

enum HandleAvailability {
  idle,
  checking,
  available,
  taken,
  invalid,
}

class OnboardingState {
  final String handleText;
  final String? handleError;
  final HandleAvailability availability;
  final List<AffiliationModel> selectedAffiliations;
  final bool saving;
  final String? errorMsg;
  final String? selectedCountry;
  final String displayNameText;

  OnboardingState({
    this.handleText = '',
    this.handleError,
    this.availability = HandleAvailability.idle,
    this.selectedAffiliations = const [],
    this.saving = false,
    this.errorMsg,
    this.selectedCountry,
    this.displayNameText = '',
  });

  OnboardingState copyWith({
    String? handleText,
    String? handleError,
    HandleAvailability? availability,
    List<AffiliationModel>? selectedAffiliations,
    bool? saving,
    String? errorMsg,
    String? selectedCountry,
    String? displayNameText,
  }) {
    return OnboardingState(
      handleText: handleText ?? this.handleText,
      handleError: handleError ?? this.handleError,
      availability: availability ?? this.availability,
      selectedAffiliations: selectedAffiliations ?? this.selectedAffiliations,
      saving: saving ?? this.saving,
      errorMsg: errorMsg ?? this.errorMsg,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      displayNameText: displayNameText ?? this.displayNameText,
    );
  }
}

class OnboardingProvider extends StateNotifier<OnboardingState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _debounceTimer;
  String? selectedCountry;

  OnboardingProvider() : super(OnboardingState());

  Map<String, dynamic> _baseUserMap(String uid) => UserModel(
    userId: uid,
    email: _auth.currentUser?.email ?? '',
    displayName: _auth.currentUser?.displayName ?? 'User',
    avatarUrl: _auth.currentUser?.photoURL,
    createdAt: DateTime.now(),
  ).toJson();

  void setHandle(String handle) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Force lowercase for uniqueness
    final cleanHandle = handle.toLowerCase();

    // Validate
    final validationError = Validators.validateHandle(cleanHandle);
    if (validationError != null) {
      state = state.copyWith(
        handleText: cleanHandle,
        handleError: validationError,
        availability: HandleAvailability.invalid,
        errorMsg: null,
      );
      return;
    }

    // If valid, start debounced availability check with explicit null error
    state = state.copyWith(
      handleText: cleanHandle,
      handleError: null,
      availability: HandleAvailability.checking,
      errorMsg: null,
    );

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkHandleAvailability(cleanHandle);
    });
  }

  void setDisplayName(String name) {
    state = state.copyWith(displayNameText: name, errorMsg: null);
  }

  Future<void> _checkHandleAvailability(String handle) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('handle', isEqualTo: handle)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        state = state.copyWith(
          handleError: null,
          availability: HandleAvailability.available,
        );
      } else {
        state = state.copyWith(
          handleError: null,
          availability: HandleAvailability.taken,
        );
      }
    } catch (e) {
      state = state.copyWith(availability: HandleAvailability.idle);
    }
  }

  void toggleAffiliation(AffiliationModel affiliation) {
    final current = state.selectedAffiliations;
    final isSelected = current.any((a) => a.id == affiliation.id);

    if (isSelected) {
      // Remove if already selected
      state = state.copyWith(
        selectedAffiliations: current.where((a) => a.id != affiliation.id).toList(),
        errorMsg: null,
      );
    } else {
      // Adding new affiliation
      if (current.length >= 8) {
        state = state.copyWith(errorMsg: 'Max 8 affiliations');
        return;
      }

      // Check type limits
      final universityCount = current.where((a) => a.type == 'university').length;
      final cityCount = current.where((a) => a.type == 'city').length;
      final interestCount = current.where((a) => a.type == 'interest').length;

      if (affiliation.type == 'university' && universityCount >= 1) {
        state = state.copyWith(errorMsg: 'You can only add 1 university');
        return;
      }

      if (affiliation.type == 'city' && cityCount >= 1) {
        state = state.copyWith(errorMsg: 'You can only add 1 city');
        return;
      }

      if (affiliation.type == 'interest' && interestCount >= 6) {
        state = state.copyWith(errorMsg: 'Max 6 interests');
        return;
      }

      // Add affiliation
      state = state.copyWith(
        selectedAffiliations: [...current, affiliation],
        errorMsg: null,
      );
    }
  }

  void swapUniversity(AffiliationModel target) {
    final withoutUniversity = state.selectedAffiliations
        .where((a) => a.type != 'university')
        .toList();
    state = state.copyWith(
      selectedAffiliations: [...withoutUniversity, target],
      errorMsg: null,
    );
  }

  void setCountry(String country) {
    selectedCountry = country;
    state = state.copyWith(selectedCountry: country, errorMsg: null);
  }

  Future<void> saveHandle(WidgetRef ref) async {
    if (state.availability != HandleAvailability.available) {
      return;
    }

    state = state.copyWith(saving: true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        state = state.copyWith(
          saving: false,
          errorMsg: 'Not signed in. Restart the app.',
        );
        return;
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('users').doc(uid);
        final doc = await transaction.get(docRef);
        final cleanHandle = state.handleText.toLowerCase();
        final displayName = state.displayNameText.trim().isEmpty ? 'User' : state.displayNameText.trim();

        if (doc.exists) {
          final existingHandle = doc.data()?['handle'];
          if (existingHandle != null && existingHandle != cleanHandle) {
            throw Exception('Handle already set to a different value');
          }
          // DOC EXISTS: ONLY write the handle and displayName. DO NOT spread _baseUserMap.
          transaction.set(docRef, {
            'handle': cleanHandle,
            'displayName': displayName,
          }, SetOptions(merge: true));
        } else {
          // DOC MISSING: Recreate doc with base map + handle + displayName.
          transaction.set(docRef, {
            ..._baseUserMap(uid),
            'handle': cleanHandle,
            'displayName': displayName,
          }, SetOptions(merge: true));
        }
      });

      // Refresh auth provider user
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        ref.read(authProvider.notifier).updateUser(userModel);
      }

      state = state.copyWith(saving: false);
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMsg: e.toString(),
      );
    }
  }

  Future<void> finish(WidgetRef ref, List<AffiliationModel> affiliations) async {
    state = state.copyWith(saving: true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        state = state.copyWith(
          saving: false,
          errorMsg: 'Not signed in. Restart the app.',
        );
        return;
      }

      final sortedAffiliations = sortAffiliationsByType(affiliations);

      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('users').doc(uid);
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          // DOC EXISTS: ONLY write affiliations and country. DO NOT spread _baseUserMap.
          transaction.set(docRef, {
            'affiliations': sortedAffiliations.map((a) => a.toMap()).toList(),
            if (selectedCountry != null) 'country': selectedCountry,
          }, SetOptions(merge: true));
        } else {
          // DOC MISSING: Recreate doc with base map + affiliations + country.
          transaction.set(docRef, {
            ..._baseUserMap(uid),
            'affiliations': sortedAffiliations.map((a) => a.toMap()).toList(),
            if (selectedCountry != null) 'country': selectedCountry,
          }, SetOptions(merge: true));
        }
      });

      // Refresh auth provider user to trigger redirect to home
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        ref.read(authProvider.notifier).updateUser(userModel);
      }

      state = state.copyWith(saving: false);
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMsg: e.toString(),
      );
    }
  }

  Future<void> skipAffiliations(WidgetRef ref) async {
    await finish(ref, []);
  }

  void reset() {
    state = OnboardingState(displayNameText: '');
  }

  Future<void> updateProfile(WidgetRef ref, String? bio, List<AffiliationModel> affiliations, {String? displayName}) async {
    state = state.copyWith(saving: true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        state = state.copyWith(
          saving: false,
          errorMsg: 'Not signed in. Restart the app.',
        );
        return;
      }

      final sortedAffiliations = sortAffiliationsByType(affiliations);

      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('users').doc(uid);
        final updateMap = {
          'bio': bio,
          'affiliations': sortedAffiliations.map((a) => a.toMap()).toList(),
        };
        if (displayName != null) {
          updateMap['displayName'] = displayName;
        }
        transaction.set(docRef, updateMap, SetOptions(merge: true));
      });

      // Refresh auth provider user
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        ref.read(authProvider.notifier).updateUser(userModel);
      }

      state = state.copyWith(saving: false);
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMsg: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingProvider, OnboardingState>((ref) {
  return OnboardingProvider();
});
