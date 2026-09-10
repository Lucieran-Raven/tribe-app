import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/search_service.dart';
import '../models/rant_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/search/user_search_card.dart';
import '../widgets/feed/rant_card.dart';
import '../design/tribe_design.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class SearchScreenReset {
  static VoidCallback? notify;
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<UserModel> _users = [];
  List<RantModel> _rants = [];
  bool _isLoading = false;
  List<String> _searchHistory = [];
  String _resultTab = 'users';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    SearchScreenReset.notify = resetSearch;
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    SearchScreenReset.notify = null;
    super.dispose();
  }

  void resetSearch() {
    _controller.clear();
    setState(() {
      _users = [];
      _rants = [];
      _isLoading = false;
    });
  }

  String _historyKey() {
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) return 'search_history_${authState.user.userId}';
    return 'search_history_guest';
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('search_history')) await prefs.remove('search_history');
    setState(() {
      _searchHistory = prefs.getStringList(_historyKey()) ?? [];
    });
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey(), _searchHistory);
  }

  void _addHistory(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _searchHistory.remove(q);
      _searchHistory.insert(0, q);
      if (_searchHistory.length > 10) _searchHistory = _searchHistory.sublist(0, 10);
    });
    _persistHistory();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _users = [];
        _rants = [];
        _isLoading = false;
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
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

      // Rank users: exact match first, then starts-with, then contains
      final lowerQuery = query.toLowerCase();
      users.sort((a, b) {
        final aHandle = (a.handle ?? '').toLowerCase();
        final bHandle = (b.handle ?? '').toLowerCase();
        final aExact = aHandle == lowerQuery ? 0 : (aHandle.startsWith(lowerQuery) ? 1 : 2);
        final bExact = bHandle == lowerQuery ? 0 : (bHandle.startsWith(lowerQuery) ? 1 : 2);
        return aExact.compareTo(bExact);
      });

      setState(() {
        _users = users;
        _rants = rants;
        _resultTab = users.isNotEmpty ? 'users' : 'posts';
        _isLoading = false;
      });
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
    final t = const TribeTheme(true);

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        appBar: GlassAppBar(title: Text('Search', style: t.display(size: 18, color: t.milk))),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClayInput(
                controller: _controller,
                hint: 'Search posts or users…',
                prefix: Icon(Icons.search, size: 16, color: t.inkFaint),
                onChanged: _onSearchChanged,
                onSubmitted: (q) {
                  _debounce?.cancel();
                  _performSearch(q);
                  _addHistory(q);
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : visibleUsers.isEmpty && visibleRants.isEmpty && _controller.text.isNotEmpty
                      ? Center(child: Text('No results for "${_controller.text}"', style: t.body(size: 13, weight: FontWeight.w600, color: t.inkFaint)))
                      : ListView(
                          children: [
                            if (_controller.text.isEmpty && _searchHistory.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Recent', style: t.caption(size: 12)),
                                    TextButton(
                                      onPressed: () {
                                        setState(() => _searchHistory = []);
                                        _persistHistory();
                                      },
                                      child: Text('Clear all', style: t.body(size: 12, weight: FontWeight.w700, color: t.gold)),
                                    ),
                                  ],
                                ),
                              ),
                              ..._searchHistory.map((term) => Container(
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      _controller.text = term;
                                      _performSearch(term);
                                      _addHistory(term);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.search, size: 14, color: t.inkFaint),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(term, style: t.body(size: 13.5, weight: FontWeight.w600, color: t.ink))),
                                        IconBtn(icon: Icons.close, size: 16, onTap: () {
                                          setState(() => _searchHistory.remove(term));
                                          _persistHistory();
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                            ],
                            if (_controller.text.isEmpty && _searchHistory.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('No recent searches.', style: t.body(size: 12.5, weight: FontWeight.w600, color: t.inkFaint)),
                              ),
                            if (visibleUsers.isNotEmpty || visibleRants.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Row(
                                  children: [
                                    if (visibleUsers.isNotEmpty) ...[
                                      TribeChip(
                                        label: 'Users',
                                        active: _resultTab == 'users',
                                        onTap: () => setState(() => _resultTab = 'users'),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (visibleRants.isNotEmpty)
                                      TribeChip(
                                        label: 'Posts',
                                        active: _resultTab == 'posts',
                                        onTap: () => setState(() => _resultTab = 'posts'),
                                      ),
                                  ],
                                ),
                              ),
                              if (_resultTab == 'users' && visibleUsers.isNotEmpty)
                                ...visibleUsers.map((user) => UserSearchCard(
                                      user: user,
                                      onTap: () {
                                        _addHistory(_controller.text);
                                        GoRouter.of(context).push('/user/${user.userId}');
                                      },
                                    )),
                              if (_resultTab == 'posts' && visibleRants.isNotEmpty)
                                ...visibleRants.map((rant) => RantCard(rant: rant)),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}


