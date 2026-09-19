import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/affiliations_seed.dart';
import '../../config/country_constants.dart';
import '../../design/tribe_design.dart';
import '../../models/affiliation_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/affiliation_sort.dart';
import '../../utils/custom_interest_utils.dart';
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
    final sortedSelected = sortAffiliationsByType(selectedAffiliations);
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
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCountryChip(t),
                            ),
                            ...['All', 'Universities', 'Cities', 'Interests'].map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: TribeChip(
                                  label: cat,
                                  active: isSelected,
                                  onTap: () {
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Interests ${selectedAffiliations.where((a) => a.type == 'interest').length}/6 selected',
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
                            children: sortedSelected.map((a) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: TribeChip(
                                  label: a.name,
                                  active: true,
                                  trailing: a.id.startsWith('custom_')
                                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.edit, size: 10, color: t.gold),
                                        const SizedBox(width: 4),
                                        Icon(Icons.close, size: 11, color: t.gold),
                                      ])
                                    : Icon(Icons.close, size: 11, color: t.gold),
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
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _selectedCountryIso == 'OTHER' && _filteredAffiliations.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 72, height: 72,
                                            decoration: BoxDecoration(
                                              color: t.bg2,
                                              borderRadius: BorderRadius.circular(24),
                                              border: Border.all(color: t.line),
                                              boxShadow: t.clayOutSm,
                                            ),
                                            child: Icon(Icons.public, size: 32, color: t.gold),
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            'TRIBE is expanding soon',
                                            style: t.display(size: 16, color: t.milk),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "We're growing across Southeast Asia. In the meantime, add your interests to connect with students nearby.",
                                            style: t.body(size: 13, weight: FontWeight.w500, color: t.inkDim),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.only(bottom: 64),
                                      children: _filteredAffiliations.map((a) {
                                        final isSelected = selectedAffiliations.any((s) => s.id == a.id);
                                        final icon = _getIconForType(a.type);
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
                                                padding: const EdgeInsets.symmetric(vertical: 6),
                                                child: NoteCard(
                                                  margin: EdgeInsets.zero,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person_outline,
                                                        size: 24,
                                                        color: isSelected ? t.gold : t.inkDim,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              a.name,
                                                              style: t.body(
                                                                size: 13.5,
                                                                weight: FontWeight.w700,
                                                                color: t.ink,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              'Studying at a university not listed?',
                                                              style: t.caption(size: 11, color: t.inkFaint),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        Icon(Icons.check_circle, size: 18, color: t.gold)
                                                      else
                                                        MiniCheckbox(checked: isSelected),
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
                                              decoration: BoxDecoration(
                                                border: Border(bottom: BorderSide(color: t.line, width: 1)),
                                              ),
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
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                if (_selectedCategory == 'Interests')
                                  Positioned(
                                    right: 16,
                                    bottom: 32,
                                    child: GestureDetector(
                                      onTap: _openAddCustomInterestSheet,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: t.bg2,
                                          borderRadius: BorderRadius.circular(100),
                                          border: Border.all(color: t.gold.withValues(alpha: 0.45)),
                                          boxShadow: t.clayOutSm,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add, size: 16, color: t.gold),
                                            const SizedBox(width: 8),
                                            Text('Add your own',
                                              style: t.body(size: 13, weight: FontWeight.w700, color: t.gold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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

  Widget _buildCountryChip(TribeTheme t) {
    final label = _selectedCountryIso == 'ALL'
        ? '🌍 All Countries'
        : _selectedCountryIso == 'OTHER'
            ? '🌐 Other'
            : '${CountryConstants.isoToFlag[_selectedCountryIso] ?? ''} '
              '${CountryConstants.isoToName[_selectedCountryIso] ?? ''}';
    return TribeChip(
      label: label,
      active: _selectedCountryIso != 'ALL',
      trailing: Icon(
        Icons.expand_more,
        size: 12,
        color: _selectedCountryIso != 'ALL' ? t.gold : t.inkDim,
      ),
      onTap: () => _openCountrySheet(context),
    );
  }

  void _openCountrySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final t = TribeTheme(isDark);
        return TribeThemeScope(
          theme: t,
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
                // Drag handle
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 16, bottom: 12),
                  decoration: BoxDecoration(
                    color: t.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(children: [
                    Expanded(child: Text('Select country',
                      style: t.display(size: 16, color: t.milk))),
                    IconBtn(icon: Icons.close, size: 18,
                      onTap: () => Navigator.of(ctx).pop()),
                  ]),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: t.line,
                ),
                // Options (scrollable if screen is short)
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _countryOption(ctx, t, 'ALL', '🌍', 'All Countries'),
                        ...CountryConstants.nameToIso.entries.map((e) =>
                          _countryOption(ctx, t, e.value,
                            CountryConstants.isoToFlag[e.value] ?? '', e.key)),
                        _countryOption(ctx, t, 'OTHER', '🌐', 'Other / Not listed'),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _countryOption(BuildContext sheetCtx, TribeTheme t, String iso,
      String flag, String name) {
    final selected = _selectedCountryIso == iso;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCountryIso = iso);
        Navigator.of(sheetCtx).pop();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? t.goldTint : Colors.transparent,
          border: Border(bottom: BorderSide(color: t.line, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(name,
            style: t.body(size: 14,
              weight: selected ? FontWeight.w700 : FontWeight.w600,
              color: t.ink))),
          if (selected) Icon(Icons.check_circle, size: 18, color: t.gold),
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
          child: ConfirmModal(
            title: 'Change affiliation?',
            body: 'Remove "${current.name}" and set your university to "${target.name}"?',
            confirmLabel: 'Change',
            onClose: () => Navigator.of(ctx).pop(),
            onConfirm: () { shouldSwap = true; },
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
}
