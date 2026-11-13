import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/countries_seed.dart';
import '../../design/tribe_design.dart';
import '../../providers/onboarding_provider.dart';

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
    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        Toast.error(context, next.errorMsg!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF8F8A8B), size: 24),
                    onPressed: () => context.go('/onboarding/3'),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '04 / LOCATION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 2.0, color: Color(0xFF8F8A8B), height: 1.4),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    const Text(
                      "WHERE'S YOUR TRIBE?",
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF), height: 1.05),
                    ),
                    const SizedBox(height: 24),
                    // Warning card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E0C0D),
                        border: Border.all(color: const Color(0xFF2B2627), width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE8A33D), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can only set this once. Choose carefully.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE8A33D)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Search field
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
                                hintText: 'Search countries...',
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
                    // Empty state
                    if (_filteredCountries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            'No countries found.',
                            style: TextStyle(color: Color(0xFF8F8A8B), fontSize: 15),
                          ),
                        ),
                      )
                    else
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _filteredCountries.map((country) {
                          final flag = _extractFlag(country);
                          final name = _extractName(country);
                          final isSelected = _selectedCountry == country;
                          return Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFF2B2627), width: 1)),
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() => _selectedCountry = country);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Row(
                                  children: [
                                    Text(flag, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFFFFFFF)),
                                      ),
                                    ),
                                    _buildV3Checkbox(isSelected),
                                  ],
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
            // Pinned Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GestureDetector(
                onTap: (_selectedCountry == null)
                    ? null
                    : () async {
                        ref.read(onboardingProvider.notifier).setCountry(_selectedCountry!);
                        if (context.mounted) {
                          context.go('/onboarding/5');
                        }
                      },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedCountry == null ? const Color(0xFF1B1819) : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: _selectedCountry == null ? const Color(0xFF8F8A8B) : const Color(0xFF0E0C0D),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildV3Checkbox(bool isSelected) {
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
}
