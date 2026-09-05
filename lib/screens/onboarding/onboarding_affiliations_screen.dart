import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/affiliations_seed.dart';
import '../../config/theme.dart';
import '../../config/obsidian_tokens.dart';
import '../../models/affiliation_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/obsidian/obsidian_dots.dart';
import '../../widgets/obsidian/obsidian_input.dart';
import '../../widgets/obsidian/obsidian_button.dart';
import '../../widgets/obsidian/obsidian_chip.dart';
import '../../widgets/obsidian/obsidian_check_row.dart';
import '../../widgets/obsidian/obsidian_snackbar.dart';

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

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        ObsidianSnackbar.show(context, next.errorMsg!, error: true);
      }
    });

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated &&
          next.user.handle != null &&
          next.user.handle!.isNotEmpty &&
          next.user.displayName != null &&
          next.user.displayName!.isNotEmpty &&
          context.mounted) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (context.mounted) context.go('/home');
        });
      }
    });

    return Scaffold(
      backgroundColor: ObsidianTokens.bg0,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Row(children: [
              SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.arrow_back, color: ObsidianTokens.inkDim), onPressed: () => context.go('/onboarding/4'))),
              const Expanded(child: Center(child: ObsidianDots(count: 5, active: 4))),
              const SizedBox(width: 40),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.map_outlined, size: 22, color: ObsidianTokens.gold),
                        const SizedBox(height: 14),
                        Text(
                          'Find your people',
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: ObsidianTokens.milk),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ObsidianInput(
                    hint: 'Search schools, cities, interests…',
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Universities', 'Cities', 'Interests'].map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ObsidianChip(
                            label: category,
                            active: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${selectedAffiliations.length}/5 selected',
                    style: GoogleFonts.inter(fontSize: 11.5, color: ObsidianTokens.inkFaint, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  if (selectedAffiliations.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedAffiliations.map((affiliation) {
                        return ObsidianChip(
                          label: affiliation.name,
                          active: true,
                          showX: true,
                          onTap: () {
                            ref.read(onboardingProvider.notifier).toggleAffiliation(affiliation);
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 14),
                  ..._filteredAffiliations.map((affiliation) {
                    final isSelected = selectedAffiliations.any((a) => a.id == affiliation.id);
                    final icon = _getIconForType(affiliation.type);
                    return ObsidianCheckRow(
                      leading: Icon(icon, size: 18, color: ObsidianTokens.inkDim),
                      title: affiliation.name,
                      subtitle: affiliation.type,
                      checked: isSelected,
                      onTap: () {
                        ref.read(onboardingProvider.notifier).toggleAffiliation(affiliation);
                      },
                    );
                  }),
                  const SizedBox(height: 14),
                  ObsidianButton(
                    label: 'Join TRIBE',
                    loading: state.saving,
                    onPressed: state.saving
                        ? null
                        : () async {
                            await ref.read(onboardingProvider.notifier).finish(ref, selectedAffiliations);
                            final currentState = ref.read(onboardingProvider);
                            if (currentState.errorMsg == null && context.mounted) {
                              context.go('/home');
                            }
                          },
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: state.saving
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
                      style: GoogleFonts.inter(fontSize: 14, color: ObsidianTokens.inkFaint, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'university':
        return Icons.school_outlined;
      case 'city':
        return Icons.location_city_outlined;
      case 'interest':
        return Icons.star_outline;
      default:
        return Icons.label_outline;
    }
  }
}
