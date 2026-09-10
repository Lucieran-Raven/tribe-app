import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../config/affiliations_seed.dart';
import '../../models/affiliation_model.dart';
import '../../models/user_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../design/tribe_design.dart';
import '../../widgets/common/avatar_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  List<AffiliationModel> _selectedAffiliations = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  File? _pickedAvatar;
  bool _isSavingAvatar = false;

  List<AffiliationModel> get _filteredAffiliations {
    var filtered = AffiliationsSeed.affiliations;

    final mappedType = {'All': null, 'Universities': 'university', 'Cities': 'city', 'Interests': 'interest'}[_selectedCategory];
    if (mappedType != null) {
      filtered = filtered.where((a) => a.type == mappedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase().trim();
      
      filtered = filtered.where((a) {
        final lowerName = a.name.toLowerCase();
        final lowerId = a.id.toLowerCase();
        
        // Exact match on name or ID
        if (lowerName == lowerQuery || lowerId == lowerQuery) return true;
        
        // Starts with
        if (lowerName.startsWith(lowerQuery) || lowerId.startsWith(lowerQuery)) return true;
        
        // Check each word in the name
        final words = lowerName.split(RegExp(r'[\s/-]+'));
        for (final word in words) {
          if (word.startsWith(lowerQuery)) return true;
        }
        
        // Check if query matches any word in the name (contains)
        for (final word in words) {
          if (word.contains(lowerQuery)) return true;
        }
        
        // Fallback to contains on full name
        return lowerName.contains(lowerQuery);
      }).toList();
      
      // Sort by relevance: exact match > starts with > word starts with > contains
      filtered.sort((a, b) {
        final lowerNameA = a.name.toLowerCase();
        final lowerNameB = b.name.toLowerCase();
        final lowerIdA = a.id.toLowerCase();
        final lowerIdB = b.id.toLowerCase();
        
        int scoreA = 0;
        int scoreB = 0;
        
        // Exact match
        if (lowerNameA == lowerQuery || lowerIdA == lowerQuery) scoreA = 100;
        if (lowerNameB == lowerQuery || lowerIdB == lowerQuery) scoreB = 100;
        
        // Starts with
        if (scoreA == 0 && (lowerNameA.startsWith(lowerQuery) || lowerIdA.startsWith(lowerQuery))) scoreA = 80;
        if (scoreB == 0 && (lowerNameB.startsWith(lowerQuery) || lowerIdB.startsWith(lowerQuery))) scoreB = 80;
        
        // Word starts with
        if (scoreA == 0) {
          final wordsA = lowerNameA.split(RegExp(r'[\s/-]+'));
          if (wordsA.any((w) => w.startsWith(lowerQuery))) scoreA = 60;
        }
        if (scoreB == 0) {
          final wordsB = lowerNameB.split(RegExp(r'[\s/-]+'));
          if (wordsB.any((w) => w.startsWith(lowerQuery))) scoreB = 60;
        }
        
        // Word contains
        if (scoreA == 0) {
          final wordsA = lowerNameA.split(RegExp(r'[\s/-]+'));
          if (wordsA.any((w) => w.contains(lowerQuery))) scoreA = 40;
        }
        if (scoreB == 0) {
          final wordsB = lowerNameB.split(RegExp(r'[\s/-]+'));
          if (wordsB.any((w) => w.contains(lowerQuery))) scoreB = 40;
        }
        
        // Contains full name
        if (scoreA == 0 && lowerNameA.contains(lowerQuery)) scoreA = 20;
        if (scoreB == 0 && lowerNameB.contains(lowerQuery)) scoreB = 20;
        
        // Sort by score descending, then alphabetically
        if (scoreA != scoreB) return scoreB.compareTo(scoreA);
        return lowerNameA.compareTo(lowerNameB);
      });
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      _bioController.text = authState.user.bio ?? '';
      _displayNameController.text = authState.user.displayName;
      _selectedAffiliations = List.from(authState.user.affiliations);
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _bioController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _searchController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _toggleAffiliation(AffiliationModel affiliation) {
    final isSelected = _selectedAffiliations.any((a) => a.id == affiliation.id);

    if (isSelected) {
      setState(() {
        _selectedAffiliations = _selectedAffiliations.where((a) => a.id != affiliation.id).toList();
      });
    } else {
      if (_selectedAffiliations.length >= 5) {
        Toast.warning(context, 'Max 5 affiliations');
        return;
      }

      final universityCount = _selectedAffiliations.where((a) => a.type == 'university').length;
      final cityCount = _selectedAffiliations.where((a) => a.type == 'city').length;
      final interestCount = _selectedAffiliations.where((a) => a.type == 'interest').length;

      if (affiliation.type == 'university' && universityCount >= 1) {
        Toast.warning(context, 'You can only add 1 university');
        return;
      }

      if (affiliation.type == 'city' && cityCount >= 1) {
        Toast.warning(context, 'You can only add 1 city');
        return;
      }

      if (affiliation.type == 'interest' && interestCount >= 3) {
        Toast.warning(context, 'Max 3 interests');
        return;
      }

      setState(() {
        _selectedAffiliations = [..._selectedAffiliations, affiliation];
      });
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'university':
        return Icons.school;
      case 'city':
        return Icons.location_city;
      case 'interest':
        return Icons.star;
      default:
        return Icons.label;
    }
  }

  Future<void> _save() async {
    final authState = ref.read(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    
    setState(() => _isSavingAvatar = true);
    
    try {
      if (_pickedAvatar != null && user != null) {
        final newAvatarUrl = await StorageService().uploadAvatar(_pickedAvatar!, user.userId);
        await FirebaseFirestore.instance.collection('users').doc(user.userId).update({'avatarUrl': newAvatarUrl});
        
        // Batch update avatar URL in all user's rants
        final rantsSnapshot = await FirebaseFirestore.instance
            .collection('rants')
            .where('userId', isEqualTo: user.userId)
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in rantsSnapshot.docs) {
          batch.update(doc.reference, {'avatarUrl': newAvatarUrl});
        }
        await batch.commit();
        
        PaintingBinding.instance.imageCache.clear();
        final freshUserDoc = await FirebaseFirestore.instance.collection('users').doc(user.userId).get();
        final freshUser = UserModel.fromJson(freshUserDoc.data() as Map<String, dynamic>);
        ref.read(authProvider.notifier).updateUser(freshUser);
      }
      
      await ref.read(onboardingProvider.notifier).updateProfile(
            ref,
            _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            _selectedAffiliations,
            displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
          );
      
      final currentState = ref.read(onboardingProvider);
      if (currentState.errorMsg == null && mounted) {
        Toast.success(context, 'Profile updated');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, 'Failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final t = const TribeTheme(true);

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMsg!)),
        );
      }
    });

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                leading: IconBtn(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                title: Text('Edit profile', style: t.display(size: 18, color: t.milk)),
                actions: [
                  _isSavingAvatar
                      ? const CupertinoActivityIndicator(radius: 8)
                      : IconBtn(
                          icon: Icons.check,
                          color: t.gold,
                          onTap: _save,
                        ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Section
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Avatar(handle: user?.handle ?? 'user', imageUrl: user?.avatarUrl, size: 86),
                            Positioned(
                              bottom: -8,
                              right: -8,
                              child: GestureDetector(
                                onTap: () async {
                                  if (!mounted) return;
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null && mounted) {
                                    try {
                                      final cropped = await AvatarCropper.crop(File(pickedFile.path), context);
                                      if (cropped != null && mounted) {
                                        setState(() => _pickedAvatar = cropped);
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        Toast.error(context, 'Failed to crop image: $e');
                                      }
                                    }
                                  }
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [t.milk, t.milkDim],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: t.clayMilkOut,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(Icons.camera_alt, size: 12, color: t.bg0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Display Name Section
                      Text('Display name', style: t.caption(size: 11.5)),
                      const SizedBox(height: 8),
                      ClayInput(
                        controller: _displayNameController,
                        maxLength: 30,
                      ),
                      const SizedBox(height: 24),
                      // Bio Section
                      Text('Bio', style: t.caption(size: 11.5)),
                      const SizedBox(height: 8),
                      ClayInput(
                        controller: _bioController,
                        maxLines: 3,
                        maxLength: 150,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('${_bioController.text.length}/150', style: t.caption(size: 11)),
                      ),
                      const SizedBox(height: 24),
                      // Affiliations Section
                      Text('Affiliations', style: t.caption(size: 11.5)),
                      const SizedBox(height: 8),
                      // Selected chips
                      if (_selectedAffiliations.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedAffiliations.map((affiliation) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getIconForType(affiliation.type), size: 16, color: t.inkDim),
                                const SizedBox(width: 8),
                                Text(affiliation.name, style: t.body(size: 13.5, weight: FontWeight.w600, color: t.ink)),
                                const SizedBox(width: 8),
                                IconBtn(icon: Icons.close, size: 14, onTap: () => _toggleAffiliation(affiliation)),
                              ],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      // Search field
                      ClayInput(
                        controller: _searchController,
                        hint: 'Search affiliations...',
                        prefix: Icon(Icons.search, size: 16, color: t.inkFaint),
                        suffix: _searchQuery.isNotEmpty
                            ? IconBtn(icon: Icons.clear, size: 16, onTap: () => _searchController.clear())
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Category chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Universities', 'Cities', 'Interests'].map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: TribeChip(
                                label: category,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                active: isSelected,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Selected count
                      Text('${_selectedAffiliations.length}/5 selected', style: t.caption(size: 11)),
                      const SizedBox(height: 8),
                      // Affiliations list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredAffiliations.length,
                        itemBuilder: (context, index) {
                          final affiliation = _filteredAffiliations[index];
                          final isSelected = _selectedAffiliations.any((a) => a.id == affiliation.id);
                          final icon = _getIconForType(affiliation.type);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(icon, size: 20, color: t.inkDim),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(affiliation.name, style: t.body(size: 14, weight: FontWeight.w500, color: t.ink)),
                                      Text(affiliation.type, style: t.caption(size: 11)),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, size: 20, color: t.gold)
                                else
                                  GestureDetector(
                                    onTap: () => _toggleAffiliation(affiliation),
                                    child: MiniCheckbox(checked: isSelected),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
