import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/affiliations_seed.dart';
import '../../config/country_constants.dart';
import '../../design/tribe_design.dart';
import '../../models/affiliation_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/custom_interest_utils.dart';

class OnboardingAffiliationsScreen extends ConsumerStatefulWidget {
  const OnboardingAffiliationsScreen({super.key});

  @override
  ConsumerState<OnboardingAffiliationsScreen> createState() => _OnboardingAffiliationsScreenState();
}

class _OnboardingAffiliationsScreenState extends ConsumerState<OnboardingAffiliationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedCountryIso = 'ALL';

  List<AffiliationModel> get _selectedAffiliationsOrState => ref.read(onboardingProvider).selectedAffiliations;

  List<AffiliationModel> get _filteredAffiliations {
    var filtered = AffiliationsSeed.affiliations;

    // Country filter — applies to universities + cities only (interests global)
    if (_selectedCountryIso != 'ALL') {
      final mappedType = {'All': null, 'Universities': 'university',
                          'Cities': 'city', 'Interests': 'interest'}[_selectedCategory];
      if (mappedType == 'university' || mappedType == 'city' || mappedType == null) {
        if (_selectedCountryIso == 'OTHER') {
          filtered = filtered.where((a) => a.type == 'interest' || a.id == 'independent').toList();
        } else {
          filtered = filtered.where((a) =>
            a.type == 'interest' || a.id == 'independent' || a.country == _selectedCountryIso
          ).toList();
        }
      }
    }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = TribeTheme(isDark);

    // Show error snackbar
    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        Toast.error(context, next.errorMsg!);
      }
    });

    // Listen for auth state changes to navigate to home after onboarding completion
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated &&
          next.user.handle != null && next.user.handle!.isNotEmpty &&
          next.user.displayName != null && next.user.displayName!.isNotEmpty &&
          context.mounted) {
        context.go('/home');
      }
    });

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER (Fixed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF8F8A8B), size: 24),
                    onPressed: () => context.go('/onboarding/4'),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '05 / AFFILIATIONS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 2.0, color: Color(0xFF8F8A8B), height: 1.4),
                  ),
                ],
              ),
            ),

            // 2. SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    const Text(
                      'FIND YOUR PEOPLE.',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF), height: 1.05),
                    ),
                    const SizedBox(height: 24),

                    // Search Field (V3)
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1819),
                        border: Border.all(color: const Color(0xFF2B2627), width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search schools, cities, interests...',
                                hintStyle: TextStyle(color: Color(0xFF8F8A8B), fontSize: 15),
                              ),
                              style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 15),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(Icons.close, size: 20, color: Color(0xFF8F8A8B)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chip Row (Existing horizontal ListView, swapped to V3 chips)
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCountryChip(t),
                          ),
                          ...['All', 'Universities', 'Cities', 'Interests'].map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildV3FilterChip(
                                cat,
                                isSelected,
                                () {
                                  setState(() {
                                    _selectedCategory = cat;
                                    if (cat == 'Interests') _selectedCountryIso = 'ALL';
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Counter (D4: Tracked caps)
                    Builder(
                      builder: (context) {
                        final interestCount = selectedAffiliations.where((s) => s.type == 'interest').length;
                        return Text(
                          'INTERESTS $interestCount/6 SELECTED',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 2.0, color: Color(0xFF8F8A8B)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // D3: V3 "OTHER" EMPTY STATE
                    if (_selectedCountryIso == 'OTHER' && _filteredAffiliations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1819),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF2B2627), width: 1),
                              ),
                              child: const Icon(Icons.public, size: 32, color: Color(0xFFE8A33D)),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'TRIBE IS EXPANDING SOON',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF), height: 1.2),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "We're growing across Southeast Asia. In the meantime, add your interests to connect with students nearby.",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8F8A8B)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      // LIST VIEW
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        children: _filteredAffiliations.map((a) {
                          final isSelected = selectedAffiliations.any((s) => s.id == a.id);
                          final icon = _getIconForType(a.type);

                          // EXISTING LIMIT LOGIC (DO NOT CHANGE)
                          final universityCount = selectedAffiliations.where((s) => s.type == 'university').length;
                          final cityCount = selectedAffiliations.where((s) => s.type == 'city').length;
                          final interestCount = selectedAffiliations.where((s) => s.type == 'interest').length;
                          final isAtTypeLimit = !isSelected && (
                            (a.type == 'university' && universityCount >= 1) ||
                            (a.type == 'city' && cityCount >= 1) ||
                            (a.type == 'interest' && interestCount >= 6)
                          );

                          if (a.id == 'independent') {
                            return Opacity(
                              opacity: isAtTypeLimit ? 0.4 : 1.0,
                              child: GestureDetector(
                                onTap: () {
                                  final hasUni = _selectedAffiliationsOrState.any(
                                    (aff) => aff.type == 'university' && aff.id != 'independent');
                                  if (hasUni) {
                                    _confirmSwap(a);
                                  } else {
                                    ref.read(onboardingProvider.notifier).toggleAffiliation(a);
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0E0C0D),
                                      border: Border.all(color: const Color(0xFF2B2627), width: 1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 24,
                                          color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF8F8A8B),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                a.name,
                                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Studying at a university not listed?',
                                                style: TextStyle(fontSize: 13, color: Color(0xFF8F8A8B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildV3AffCheckbox(isSelected),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return Opacity(
                            opacity: isAtTypeLimit ? 0.4 : 1.0,
                            child: GestureDetector(
                              onTap: () {
                                if (a.id == 'independent') {
                                  final hasUni = _selectedAffiliationsOrState.any(
                                    (aff) => aff.type == 'university' && aff.id != 'independent');
                                  if (hasUni) {
                                    _confirmSwap(a);
                                  } else {
                                    ref.read(onboardingProvider.notifier).toggleAffiliation(a);
                                  }
                                  return;
                                }
                                if (isAtTypeLimit && a.type == 'university') {
                                  _confirmSwap(a);
                                  return;
                                }
                                if (isAtTypeLimit) return;
                                ref.read(onboardingProvider.notifier).toggleAffiliation(a);
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFF2B2627), width: 1)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(icon, size: 20, color: const Color(0xFF8F8A8B)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.name,
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFFFFFFF)),
                                            ),
                                            Text(
                                              a.type,
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF8F8A8B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildV3AffCheckbox(isSelected),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            // 3. PINNED BOTTOM ACTIONS
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Join TRIBE Button
                  GestureDetector(
                    onTap: state.saving
                        ? null
                        : () async {
                            await ref.read(onboardingProvider.notifier).finish(ref, selectedAffiliations);
                            final currentState = ref.read(onboardingProvider);
                            if (currentState.errorMsg == null && context.mounted) {
                              context.go('/home');
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: state.saving ? const Color(0xFF1B1819) : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: state.saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Color(0xFF8F8A8B), strokeWidth: 2),
                              )
                            : const Text(
                                'JOIN TRIBE',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.4, color: Color(0xFF0E0C0D)),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Skip for now Button
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
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      alignment: Alignment.center,
                      child: const Text(
                        'SKIP FOR NOW',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.4, color: Color(0xFF8F8A8B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCountryChip(TribeTheme t) {
    final String label;
    if (_selectedCountryIso == 'ALL') {
      label = 'All Countries';
    } else if (_selectedCountryIso == 'OTHER') {
      label = 'Other';
    } else {
      label = CountryConstants.isoToName[_selectedCountryIso] ?? 'Country';
    }
    return _buildV3CountryChip(
      label,
      _selectedCountryIso != 'ALL',
      () => _openCountrySheet(context),
    );
  }

  void _openCountrySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            border: Border(top: BorderSide(color: Color(0xFF2B2627), width: 1)),
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Padding(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(ctx).padding.top + 40, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('05.1 / FILTER',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                                letterSpacing: 2.0, color: Color(0xFF8F8A8B))),
                            const SizedBox(height: 12),
                            const Text('SELECT COUNTRY',
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w400,
                                height: 1.0, color: Color(0xFFFFFFFF))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.close, size: 24, color: Color(0xFFFFFFFF)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFF2B2627)),
                // OPTIONS
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _countryOption(ctx, 'ALL', '', 'All Countries'),
                        ...CountryConstants.nameToIso.entries.map((e) =>
                          _countryOption(ctx, e.value,
                            CountryConstants.isoToFlag[e.value] ?? '', e.key)),
                        _countryOption(ctx, 'OTHER', '🌐', 'Other / Not listed'),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _countryOption(BuildContext sheetCtx, String iso, String flag, String name) {
    final selected = _selectedCountryIso == iso;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCountryIso = iso);
        Navigator.of(sheetCtx).pop();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B1819) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0xFF2B2627), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(children: [
          if (iso == 'ALL')
            const Icon(Icons.language, size: 24, color: Color(0xFFF4F1F0))
          else
            Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(child: Text(name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFFFFFFFF),
            ))),
          if (selected) const Icon(Icons.check, size: 22, color: Color(0xFFFFFFFF)),
        ]),
      ),
    );
  }

  Future<void> _confirmSwap(AffiliationModel target) async {
    final current = _selectedAffiliationsOrState.firstWhere(
      (a) => a.type == 'university',
      orElse: () => target,
    );
    if (current.id == target.id) return;

    bool shouldSwap = false;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return TribeThemeScope(
          theme: TribeTheme(isDark),
          child: _V3ConfirmDialog(
            title: 'Change affiliation?',
            body: 'Remove "${current.name}" and set your university to "${target.name}"?',
            confirmLabel: 'Change',
            onClose: () => Navigator.of(ctx).pop(),
            onConfirm: () {
              shouldSwap = true;
              Navigator.of(ctx).pop();
            },
          ),
        );
      },
    );

    if (!shouldSwap) return;
    if (!mounted) return;
    _applySwap(target);
  }

  void _applySwap(AffiliationModel target) {
    ref.read(onboardingProvider.notifier).swapUniversity(target);
  }

  Future<void> _openAddCustomInterestSheet() async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final t = TribeTheme(isDark);
        return TribeThemeScope(
          theme: t,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: t.bg1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: t.lineStrong)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 16, bottom: 12), decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(4))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(children: [
                      Expanded(child: Text('Add your own', style: t.display(size: 16, color: t.milk))),
                      IconBtn(icon: Icons.close, size: 18, onTap: () => Navigator.of(ctx).pop()),
                    ]),
                  ),
                  Divider(height: 1, thickness: 1, color: t.line),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: ClayInput(controller: controller, hint: 'e.g. Scuba Diving', maxLength: 40),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: t.gold, foregroundColor: t.bg1),
                        onPressed: () {
                          final raw = controller.text;
                          final error = CustomInterestUtils.validateName(raw);
                          if (error != null) {
                            Navigator.of(ctx).pop();
                            Toast.warning(context, error);
                            return;
                          }
                          final titleName = CustomInterestUtils.toTitleCase(raw);
                          final customId = CustomInterestUtils.toCustomId(raw);
                          Navigator.of(ctx).pop();
                          _addCustomInterest(titleName, customId);
                        },
                        child: Text('Add interest', style: t.body(size: 14, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  void _addCustomInterest(String titleName, String customId) {
    final currentList = ref.read(onboardingProvider).selectedAffiliations;
    final interestCount = currentList.where((a) => a.type == 'interest').length;

    if (interestCount >= 6) {
      Toast.warning(context, 'Max 6 interests');
      return;
    }

    final lowerName = titleName.toLowerCase();
    final seedMatch = AffiliationsSeed.affiliations.firstWhere(
      (a) => a.type == 'interest' && a.name.toLowerCase() == lowerName,
      orElse: () => AffiliationModel(id: '', name: '', type: 'interest'),
    );

    if (seedMatch.id.isNotEmpty) {
      final alreadySelected = currentList.any((a) => a.id == seedMatch.id);
      if (alreadySelected) {
        Toast.info(context, '"${seedMatch.name}" already selected');
        return;
      }
      ref.read(onboardingProvider.notifier).toggleAffiliation(seedMatch);
      return;
    }

    if (currentList.any((a) => a.id == customId)) {
      Toast.info(context, '"$titleName" already added');
      return;
    }

    final custom = AffiliationModel(
      id: customId,
      name: titleName,
      type: 'interest',
      verified: false,
      country: null,
    );
    ref.read(onboardingProvider.notifier).toggleAffiliation(custom);
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

  Widget _buildV3AffCheckbox(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF1B1819),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF2B2627),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Color(0xFF0E0C0D))
          : null,
    );
  }

  Widget _buildV3FilterChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF1B1819),
          border: Border.all(
            color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF2B2627),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? const Color(0xFF0E0C0D) : const Color(0xFFF4F1F0),
          ),
        ),
      ),
    );
  }

  Widget _buildV3CountryChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF1B1819),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF2B2627),
            width: 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isActive ? const Color(0xFF0E0C0D) : const Color(0xFFF4F1F0),
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.expand_more, size: 12,
            color: isActive ? const Color(0xFFE8A33D) : const Color(0xFF8F8A8B)),
        ]),
      ),
    );
  }
}

class _V3ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onClose;
  final VoidCallback onConfirm;
  const _V3ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0C0D),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2B2627), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                const SizedBox(height: 10),
                Text(body, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w400,
                  height: 1.46, color: Color(0xFFF4F1F0))),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1819),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF2B2627), width: 1),
                        ),
                        child: const Center(child: Text('Cancel', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: Color(0xFF8F8A8B)))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(child: Text(confirmLabel, style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: Color(0xFF0E0C0D)))),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

