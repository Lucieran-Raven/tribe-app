import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/painting.dart';
import '../../config/affiliations_seed.dart';
import '../../config/theme.dart';
import '../../models/affiliation_model.dart';
import '../../models/user_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
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

  List<AffiliationModel> get _filteredAffiliations {
    var filtered = AffiliationsSeed.affiliations;

    final mappedType = {'All': null, 'Universities': 'university', 'Cities': 'city', 'Interests': 'interest'}[_selectedCategory];
    if (mappedType != null) {
      filtered = filtered.where((a) => a.type == mappedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) => a.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Max 5 affiliations')),
        );
        return;
      }

      final universityCount = _selectedAffiliations.where((a) => a.type == 'university').length;
      final cityCount = _selectedAffiliations.where((a) => a.type == 'city').length;
      final interestCount = _selectedAffiliations.where((a) => a.type == 'interest').length;

      if (affiliation.type == 'university' && universityCount >= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only add 1 university')),
        );
        return;
      }

      if (affiliation.type == 'city' && cityCount >= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only add 1 city')),
        );
        return;
      }

      if (affiliation.type == 'interest' && interestCount >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Max 3 interests')),
        );
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMsg!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: state.saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: state.saving
                ? null
                : () async {
                    // Upload avatar if picked
                    if (_pickedAvatar != null && user != null) {
                      try {
                        final newAvatarUrl = await StorageService().uploadAvatar(_pickedAvatar!, user.userId);
                        await FirebaseFirestore.instance.collection('users').doc(user.userId).update({'avatarUrl': newAvatarUrl});
                        PaintingBinding.instance.imageCache.clear();
                        final freshUserDoc = await FirebaseFirestore.instance.collection('users').doc(user.userId).get();
                        final freshUser = UserModel.fromJson(freshUserDoc.data() as Map<String, dynamic>);
                        ref.read(authProvider.notifier).updateUser(freshUser);
                      } catch (e) {
                        print('AVATAR UPLOAD FAILED: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Avatar upload failed: $e')));
                        }
                        return; // Stop saving profile if upload fails
                      }
                    }
                    await ref.read(onboardingProvider.notifier).updateProfile(
                          ref,
                          _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
                          _selectedAffiliations,
                          displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
                        );
                    final currentState = ref.read(onboardingProvider);
                    if (currentState.errorMsg == null && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _pickedAvatar != null 
                        ? FileImage(_pickedAvatar!) 
                        : (user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null),
                    child: _pickedAvatar == null && user?.avatarUrl == null 
                        ? const Icon(Icons.person, size: 60) 
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
                        if (pickedFile != null) {
                          setState(() => _pickedAvatar = File(pickedFile.path));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.brandPrimary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Display Name Section
            TextField(
              controller: _displayNameController,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            // Bio Section
            Text(
              'Bio',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Tell us about yourself...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Affiliations Section
            Text(
              'Affiliations',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search affiliations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Category chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Universities', 'Cities', 'Interests'].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: AppTheme.brandPrimary.withOpacity(0.2),
                      checkmarkColor: AppTheme.brandPrimary,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Selected count
            Text(
              '${_selectedAffiliations.length}/5 selected',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Selected chips
            SizedBox(
              height: 48,
              child: _selectedAffiliations.isNotEmpty
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      children: _selectedAffiliations.map((affiliation) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(affiliation.name),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              _toggleAffiliation(affiliation);
                            },
                            backgroundColor: AppTheme.brandPrimary.withOpacity(0.1),
                          ),
                        );
                      }).toList(),
                    )
                  : null,
            ),
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

                return ListTile(
                  leading: Icon(icon),
                  title: Text(affiliation.name),
                  subtitle: Text(affiliation.type),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppTheme.brandPrimary)
                      : Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            _toggleAffiliation(affiliation);
                          },
                        ),
                  onTap: () {
                    _toggleAffiliation(affiliation);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
