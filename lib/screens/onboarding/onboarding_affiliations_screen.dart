import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/affiliations_seed.dart';
import '../../config/theme.dart';
import '../../models/affiliation_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/onboarding/onboarding_page_indicator.dart';
import '../../widgets/onboarding/onboarding_page_indicator.dart';

class OnboardingAffiliationsScreen extends ConsumerStatefulWidget {
  const OnboardingAffiliationsScreen({super.key});

  @override
  ConsumerState<OnboardingAffiliationsScreen> createState() => _OnboardingAffiliationsScreenState();
}

class _OnboardingAffiliationsScreenState extends ConsumerState<OnboardingAffiliationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<AffiliationModel> get _filteredAffiliations {
    var filtered = AffiliationsSeed.affiliations;

    // Filter by category with mapping
    final mappedType = {'All': null, 'Universities': 'university', 'Cities': 'city', 'Interests': 'interest'}[_selectedCategory];
    if (mappedType != null) {
      filtered = filtered.where((a) => a.type == mappedType).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) => a.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final selectedAffiliations = state.selectedAffiliations;

    // Show error snackbar
    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMsg!)),
        );
      }
    });

    // Listen for auth state changes to navigate to home after onboarding completion
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated &&
          next.user.handle != null &&
          next.user.handle!.isNotEmpty &&
          next.user.displayName != null &&
          next.user.displayName!.isNotEmpty &&
          context.mounted) {
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding/4'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Icon
            Icon(
              Icons.map_rounded,
              size: 64,
              color: AppTheme.brandPrimary,
            ),
            const SizedBox(height: 8),
            // Headline
            Text(
              'Where do you belong?',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Body
            Text(
              'Add your university, city, and interests. This helps us show you rants that matter.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
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
            ),
            const SizedBox(height: 8),
            // Category chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${selectedAffiliations.length}/5 selected',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Selected chips (fixed height)
            SizedBox(
              height: 48,
              child: selectedAffiliations.isNotEmpty
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: selectedAffiliations.map((affiliation) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(affiliation.name),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              ref.read(onboardingProvider.notifier).toggleAffiliation(affiliation);
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredAffiliations.length,
                itemBuilder: (context, index) {
                  final affiliation = _filteredAffiliations[index];
                  final isSelected = selectedAffiliations.any((a) => a.id == affiliation.id);
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
                              ref.read(onboardingProvider.notifier).toggleAffiliation(affiliation);
                            },
                          ),
                    onTap: () {
                      ref.read(onboardingProvider.notifier).toggleAffiliation(affiliation);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Bottom buttons outside scrollable body
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.saving
                      ? null
                      : () async {
                          await ref.read(onboardingProvider.notifier).finish(ref, selectedAffiliations);
                          final currentState = ref.read(onboardingProvider);
                          if (currentState.errorMsg == null && context.mounted) {
                            context.go('/home');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                  ),
                  ),
                  child: state.saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Join TRIBE',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: state.saving
                    ? null
                    : () async {
                        await ref.read(onboardingProvider.notifier).skipAffiliations(ref);
                        final currentState = ref.read(onboardingProvider);
                        if (currentState.errorMsg == null && context.mounted) {
                          context.go('/home');
                        }
                      },
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const OnboardingPageIndicator(activeIndex: 4),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
}
