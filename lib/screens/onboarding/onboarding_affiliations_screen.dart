import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/affiliations_seed.dart';
import '../../design/tribe_design.dart';
import '../../models/affiliation_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
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

    // Filter by search with intelligent matching
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
    final t = const TribeTheme(true);

    // Show error snackbar
    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        Toast.error(context, next.errorMsg!);
      }
    });

    // Listen for auth state changes to navigate to home after onboarding completion
    ref.listen<AuthState>(authProvider, (previous, next) {
      // ignore: unnecessary_null_comparison
      if (next is AuthAuthenticated &&
          next.user.handle != null &&
          // ignore: unnecessary_non_null_assertion
          next.user.handle!.isNotEmpty &&
          // ignore: unnecessary_null_comparison
          next.user.displayName != null &&
          // ignore: unnecessary_non_null_assertion
          next.user.displayName!.isNotEmpty &&
          context.mounted) {
        context.go('/home');
      }
    });

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              // 1. HEADER ROW FIRST
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconBtn(icon: Icons.arrow_back, onTap: () => context.go('/onboarding/4')),
                    const OnboardingPageIndicator(activeIndex: 4),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              // 2. CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.location_on_outlined, size: 22, color: t.gold),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Find your people',
                          style: t.display(size: 18, color: t.milk),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClayInput(
                        hint: 'Search schools, cities, interests…',
                        controller: _searchController,
                        suffix: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                },
                                child: Icon(Icons.close, size: 18, color: t.inkFaint),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      // filter chips — REAL category logic
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: ['All', 'Universities', 'Cities', 'Interests'].map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: TribeChip(
                                label: cat,
                                active: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${selectedAffiliations.length}/5 selected',
                          style: t.caption(size: 11.5),
                        ),
                      ),
                      // selected chips horizontal scroll (only when selections exist)
                      if (selectedAffiliations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: selectedAffiliations.map((a) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: TribeChip(
                                  label: a.name,
                                  active: true,
                                  trailing: Icon(Icons.close, size: 11, color: t.gold),
                                  onTap: () {
                                    ref.read(onboardingProvider.notifier).toggleAffiliation(a);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // 3. LIST — REAL SEED DATA
                      Expanded(
                        child: ListView(
                          children: _filteredAffiliations.map((a) {
                            final isSelected = selectedAffiliations.any((s) => s.id == a.id);
                            final icon = _getIconForType(a.type);
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: t.line, width: 1)),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  ref.read(onboardingProvider.notifier).toggleAffiliation(a);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(icon, size: 18, color: t.inkDim),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.name,
                                              style: t.body(size: 13.5, weight: FontWeight.w600, color: t.ink),
                                            ),
                                            Text(
                                              a.type,
                                              style: t.caption(size: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      MiniCheckbox(checked: isSelected),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // 4. BUTTONS PINNED BOTTOM
                      const SizedBox(height: 6),
                      ClayButtonPrimary(
                        label: 'Join TRIBE',
                        onTap: state.saving
                            ? null
                            : () async {
                                await ref.read(onboardingProvider.notifier).finish(ref, selectedAffiliations);
                                final currentState = ref.read(onboardingProvider);
                                if (currentState.errorMsg == null && context.mounted) {
                                  context.go('/home');
                                }
                              },
                      ),
                      const SizedBox(height: 6),
                      ClayButtonSecondary(
                        label: 'Skip for now',
                        plain: true,
                        textColor: t.inkFaint,
                        onTap: state.saving
                            ? null
                            : () async {
                                await ref.read(onboardingProvider.notifier).skipAffiliations(ref);
                                final currentState = ref.read(onboardingProvider);
                                if (currentState.errorMsg == null && context.mounted) {
                                  context.go('/home');
                                }
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
