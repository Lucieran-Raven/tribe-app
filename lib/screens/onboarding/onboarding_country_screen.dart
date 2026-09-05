import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/countries_seed.dart';
import '../../config/theme.dart';
import '../../config/obsidian_tokens.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/obsidian/obsidian_dots.dart';
import '../../widgets/obsidian/obsidian_input.dart';
import '../../widgets/obsidian/obsidian_button.dart';
import '../../widgets/obsidian/obsidian_check_row.dart';
import '../../widgets/obsidian/obsidian_snackbar.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            ObsidianSnackbar.show(context, next.errorMsg!, error: true);
          }
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
              SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.arrow_back, color: ObsidianTokens.inkDim), onPressed: () => context.go('/onboarding/3'))),
              const Expanded(child: Center(child: ObsidianDots(count: 5, active: 3))),
              const SizedBox(width: 40),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.public, size: 22, color: ObsidianTokens.gold),
                        const SizedBox(height: 16),
                        Text(
                          "Where's your tribe?",
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: ObsidianTokens.milk),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: ObsidianTokens.bg2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ObsidianTokens.line(false)),
                      boxShadow: ObsidianTokens.clayOutSmDark,
                    ),
                    child: Text(
                      '⚠ You can only set this once. Choose carefully.',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ObsidianTokens.inkDim),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ObsidianInput(
                    hint: 'Search countries…',
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ..._filteredCountries.map((country) {
                    final isSelected = _selectedCountry == country;
                    return ObsidianCheckRow(
                      leading: Text(_getFlag(country), style: const TextStyle(fontSize: 20)),
                      title: country,
                      checked: isSelected,
                      onTap: () {
                        setState(() => _selectedCountry = country);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  ObsidianButton(
                    label: 'Next',
                    onPressed: (_selectedCountry == null || state.saving)
                        ? null
                        : () async {
                            ref.read(onboardingProvider.notifier).setCountry(_selectedCountry!);
                            if (context.mounted) {
                              context.go('/onboarding/5');
                            }
                          },
                    loading: state.saving,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFlag(String country) {
    if (country == 'United States') return '🇺🇸';
    if (country == 'United Kingdom') return '🇬🇧';
    if (country == 'Canada') return '🇨🇦';
    if (country == 'Australia') return '🇦🇺';
    if (country == 'Germany') return '🇩🇪';
    if (country == 'France') return '🇫🇷';
    if (country == 'India') return '🇮🇳';
    if (country == 'Japan') return '🇯🇵';
    if (country == 'Brazil') return '🇧🇷';
    if (country == 'Mexico') return '🇲🇽';
    if (country == 'South Korea') return '🇰🇷';
    if (country == 'Italy') return '🇮🇹';
    if (country == 'Spain') return '🇪🇸';
    if (country == 'Netherlands') return '🇳🇱';
    if (country == 'Sweden') return '🇸🇪';
    if (country == 'Norway') return '🇳🇴';
    if (country == 'Denmark') return '🇩🇰';
    if (country == 'Finland') return '🇫🇮';
    if (country == 'Poland') return '🇵🇱';
    if (country == 'Turkey') return '🇹🇷';
    if (country == 'Argentina') return '🇦🇷';
    if (country == 'Colombia') return '🇨🇴';
    if (country == 'Chile') return '🇨🇱';
    if (country == 'Peru') return '🇵🇪';
    if (country == 'South Africa') return '🇿🇦';
    if (country == 'Egypt') return '🇪🇬';
    if (country == 'Nigeria') return '🇳🇬';
    if (country == 'Kenya') return '🇰🇪';
    if (country == 'Morocco') return '🇲🇦';
    if (country == 'Saudi Arabia') return '🇸🇦';
    if (country == 'UAE') return '🇦🇪';
    if (country == 'Indonesia') return '🇮🇩';
    if (country == 'Malaysia') return '🇲🇾';
    if (country == 'Singapore') return '🇸🇬';
    if (country == 'Thailand') return '🇹🇭';
    if (country == 'Vietnam') return '🇻🇳';
    if (country == 'Philippines') return '🇵🇭';
    if (country == 'China') return '🇨🇳';
    if (country == 'Hong Kong') return '🇭🇰';
    if (country == 'Taiwan') return '🇹🇼';
    if (country == 'New Zealand') return '🇳🇿';
    if (country == 'Ireland') return '🇮🇪';
    if (country == 'Switzerland') return '🇨🇭';
    if (country == 'Belgium') return '🇧🇪';
    if (country == 'Austria') return '🇦🇹';
    if (country == 'Czech Republic') return '🇨🇿';
    if (country == 'Greece') return '🇬🇷';
    if (country == 'Portugal') return '🇵🇹';
    if (country == 'Russia') return '🇷🇺';
    if (country == 'Ukraine') return '🇺🇦';
    if (country == 'Israel') return '🇮🇱';
    if (country == 'Pakistan') return '🇵🇰';
    if (country == 'Bangladesh') return '🇧🇩';
    return '🌍';
  }
}
