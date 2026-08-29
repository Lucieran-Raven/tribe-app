import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../services/search_service.dart';
import '../models/rant_model.dart';
import '../models/user_model.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
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
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search rants or users...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty && _rants.isEmpty && _controller.text.isNotEmpty
                    ? const Center(child: Text('No results found.'))
                    : ListView(
                        children: [
                          if (_users.isNotEmpty) ...[
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
                            ..._users.map((user) => UserSearchCard(
                                  user: user,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Public profiles coming soon')),
                                    );
                                  },
                                )),
                          ],
                          if (_rants.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                'Rants',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            ..._rants.map((rant) => RantCard(rant: rant)),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
