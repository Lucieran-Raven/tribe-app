import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search posts or users...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleUsers.isEmpty && visibleRants.isEmpty && _controller.text.isNotEmpty
                    ? const Center(child: Text('No results found.'))
                    : ListView(
                        children: [
                          if (_controller.text.isEmpty && _searchHistory.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  TextButton(
                                    onPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.remove('search_history');
                                      setState(() => _searchHistory = []);
                                    },
                                    child: const Text('Clear All'),
                                  ),
                                ],
                              ),
                            ),
                            ..._searchHistory.map((term) => ListTile(
                              leading: const Icon(Icons.history, color: Colors.grey),
                              title: Text(term),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () async {
                                  setState(() => _searchHistory.remove(term));
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setStringList('search_history', _searchHistory);
                                },
                              ),
                              onTap: () {
                                _controller.text = term;
                                _performSearch(term);
                              },
                            )),
                          ],
                          if (visibleUsers.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text(
                                'Users',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            ...visibleUsers.map((user) => UserSearchCard(
                                  user: user,
                                  onTap: () {
                                    GoRouter.of(context).push('/user/${user.userId}');
                                  },
                                )),
                          ],
                          if (visibleRants.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                'Posts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
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
