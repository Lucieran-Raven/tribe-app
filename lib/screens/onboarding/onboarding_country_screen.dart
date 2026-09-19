import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/countries_seed.dart';
import '../../design/tribe_design.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding/onboarding_page_indicator.dart';

class OnboardingCountryScreen extends ConsumerStatefulWidget {
  const OnboardingCountryScreen({super.key});

  @override
  ConsumerState<OnboardingCountryScreen> createState() => _OnboardingCountryScreenState();
}

class _OnboardingCountryScreenState extends ConsumerState<OnboardingCountryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCountry;

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

  List<String> get _filteredCountries {
    if (_searchQuery.isEmpty) {
      return CountriesSeed.countries;
    }
    return CountriesSeed.countries
        .where((country) => country.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  String _extractFlag(String country) {
    final lastSpaceIndex = country.lastIndexOf(' ');
    if (lastSpaceIndex == -1) return '';
    return country.substring(lastSpaceIndex + 1);
  }

  String _extractName(String country) {
    final lastSpaceIndex = country.lastIndexOf(' ');
    if (lastSpaceIndex == -1) return country;
    return country.substring(0, lastSpaceIndex);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = TribeTheme(isDark);

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        Toast.error(context, next.errorMsg!);
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
                    IconBtn(icon: Icons.arrow_back, onTap: () => context.go('/onboarding/3')),
                    const OnboardingPageIndicator(activeIndex: 3),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              // 2. CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.public, size: 22, color: t.gold),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Where's your tribe?",
                          style: t.display(size: 18, color: t.milk),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // warning pill
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        decoration: BoxDecoration(
                          color: t.bg2,
                          border: Border.all(color: t.line),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: t.clayOutSm,
                        ),
                        child: Text(
                          '⚠ You can only set this once. Choose carefully.',
                          style: t.body(size: 12, weight: FontWeight.w700, color: t.inkDim),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClayInput(
                        hint: 'Search countries…',
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
                      const SizedBox(height: 8),
                      // 3. LIST WITH FLAGS — REAL DATA
                      Expanded(
                        child: ListView(
                          children: _filteredCountries.map((country) {
                            final flag = _extractFlag(country);
                            final name = _extractName(country);
                            final isSelected = _selectedCountry == country;
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: t.line, width: 1)),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCountry = country);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Text(flag, style: const TextStyle(fontSize: 20)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: t.body(size: 14, weight: FontWeight.w600, color: t.ink),
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
                      const SizedBox(height: 8),
                      // 4. NEXT PINNED BOTTOM
                      ClayButtonPrimary(
                        label: 'Next',
                        onTap: (_selectedCountry == null || state.saving)
                            ? null
                            : () async {
                                ref.read(onboardingProvider.notifier).setCountry(_selectedCountry!);
                                if (context.mounted) {
                                  context.go('/onboarding/5');
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
}
