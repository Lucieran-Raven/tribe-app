import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/search_service.dart';
import '../models/rant_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/search/user_search_card.dart';
import '../widgets/feed/rant_card.dart';
import '../config/obsidian_tokens.dart';
import '../widgets/obsidian/obsidian_input.dart';
import '../widgets/obsidian/tribe_avatar.dart';
import '../widgets/obsidian/obsidian_empty_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<UserModel> _users = [];
  List<RantModel> _rants = [];
  bool _isLoading = false;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      if (query.isEmpty) {
        setState(() {
          _users = [];
          _rants = [];
          _isLoading = false;
        });
        return;
      }

      final searchService = SearchService();
      final users = await searchService.searchUsers(query);
      final rants = await searchService.searchRants(query);

      setState(() {
        _users = users;
        _rants = rants;
        _isLoading = false;
      });

      if (query.isNotEmpty) {
        _searchHistory.remove(query);
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) _searchHistory = _searchHistory.sublist(0, 10);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('search_history', _searchHistory);
        setState(() {});
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final blocked = authState is AuthAuthenticated ? authState.user.blockedUsers : const <String>[];
    final visibleUsers = _users.where((u) => !blocked.contains(u.userId)).toList();
    final visibleRants = _rants.where((r) => !blocked.contains(r.userId)).toList();

    return Scaffold(
      backgroundColor: ObsidianTokens.bg0,
      appBar: AppBar(
        backgroundColor: const Color(0x13FFFFFF),
        elevation: 0,
        title: Text(
          'Search',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ObsidianTokens.milk,
          ),
        ),
        shape: const Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ObsidianInput(
              controller: _controller,
              hint: 'Search posts or users…',
              prefix: Icon(Icons.search, size: 16, color: ObsidianTokens.inkFaint),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleUsers.isEmpty && visibleRants.isEmpty && _controller.text.isNotEmpty
                    ? ObsidianEmptyState(
                        icon: Icons.search_off,
                        headline: 'No results for "${_controller.text}"',
                      )
                    : ListView(
                        children: [
                          if (_controller.text.isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: ObsidianTokens.inkFaint,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.remove('search_history');
                                      setState(() => _searchHistory = []);
                                    },
                                    child: Text(
                                      'Clear all',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: ObsidianTokens.gold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_searchHistory.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                child: Text(
                                  'No recent searches.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: ObsidianTokens.inkFaint,
                                  ),
                                ),
                              )
                            else
                              ..._searchHistory.map((term) => GestureDetector(
                                    onTap: () {
                                      _controller.text = term;
                                      _performSearch(term);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: ObsidianTokens.line(false))),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.search, size: 14, color: ObsidianTokens.inkFaint),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              term,
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: ObsidianTokens.ink,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.close, size: 14, color: ObsidianTokens.inkFaint),
                                            onPressed: () async {
                                              setState(() => _searchHistory.remove(term));
                                              final prefs = await SharedPreferences.getInstance();
                                              await prefs.setStringList('search_history', _searchHistory);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                          ],
                          if (visibleUsers.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                              child: Text(
                                'Users',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ObsidianTokens.inkFaint,
                                ),
                              ),
                            ),
                            ...visibleUsers.map((user) => GestureDetector(
                                  onTap: () {
                                    GoRouter.of(context).push('/user/${user.userId}');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: ObsidianTokens.line(false))),
                                    ),
                                    child: Row(
                                      children: [
                                        TribeAvatar(
                                          handle: user.handle ?? 'user',
                                          avatarUrl: user.avatarUrl,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.displayName ?? user.handle ?? 'User',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: ObsidianTokens.ink,
                                                ),
                                              ),
                                              Text(
                                                '@${user.handle ?? 'user'}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: ObsidianTokens.inkDim,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                          if (visibleRants.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                              child: Text(
                                'Posts',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ObsidianTokens.inkFaint,
                                ),
                              ),
                            ),
                            ...visibleRants.map((rant) => RantCard(rant: rant)),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
