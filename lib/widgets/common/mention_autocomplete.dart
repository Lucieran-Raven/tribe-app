import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/search_service.dart';
import '../../models/user_model.dart';
import '../../design/tribe_design.dart';

class MentionAutocomplete extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueNotifier<List<String>> mentionedUserIds;
  final Widget child;

  const MentionAutocomplete({
    super.key,
    required this.controller,
    required this.mentionedUserIds,
    required this.child,
  });

  @override
  ConsumerState<MentionAutocomplete> createState() => _MentionAutocompleteState();
}

class _MentionAutocompleteState extends ConsumerState<MentionAutocomplete> {
  final List<UserModel> _matchedUsers = [];
  String _currentQuery = '';
  bool _showDropdown = false;

  List<UserModel> get matchedUsers => _matchedUsers;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;

    // Find the word at the cursor position
    if (cursorPosition >= 0) {
      final textBeforeCursor = text.substring(0, cursorPosition);
      final lastSpaceIndex = textBeforeCursor.lastIndexOf(' ');
      final wordStart = lastSpaceIndex == -1 ? 0 : lastSpaceIndex + 1;
      final currentWord = textBeforeCursor.substring(wordStart);

      // Check if current word starts with @
      if (currentWord.startsWith('@') && currentWord.length > 1) {
        final query = currentWord.substring(1).toLowerCase();
        final hardCap = widget.mentionedUserIds.value.length >= 5;

        if (!hardCap && query != _currentQuery) {
          _currentQuery = query;
          _searchUsers(query);
        } else if (hardCap) {
          _hideDropdown();
        }
      } else {
        _hideDropdown();
      }
    } else {
      _hideDropdown();
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _hideDropdown();
      return;
    }

    try {
      final users = await SearchService().searchUsers(query);
      if (mounted) {
        setState(() {
          _matchedUsers.clear();
          _matchedUsers.addAll(users);
          _showDropdown = users.isNotEmpty;
        });
      }
    } catch (e) {
      _hideDropdown();
    }
  }

  void _hideDropdown() {
    setState(() {
      _showDropdown = false;
      _matchedUsers.clear();
      _currentQuery = '';
    });
  }

  void _onSelectUser(UserModel user) {
    final text = widget.controller.text;
    final handle = user.handle ?? 'anonymous';

    // 1. Find the last '@' in the text.
    // (Safe because the dropdown is ONLY visible when an active '@' is being typed).
    int atIndex = text.lastIndexOf('@');

    if (atIndex != -1) {
      // 2. Replace everything from the last '@' to the end of the text
      final newText = text.substring(0, atIndex) + '@$handle ';
      widget.controller.text = newText;

      // 3. Force cursor to the end
      widget.controller.selection = TextSelection.collapsed(offset: newText.length);
    }

    // 4. Add to mentionedUserIds (keep existing logic)
    if (!widget.mentionedUserIds.value.contains(user.userId)) {
      widget.mentionedUserIds.value = [...widget.mentionedUserIds.value, user.userId];
    }

    _hideDropdown();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = TribeTheme(isDark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showDropdown) _buildDropdownUI(t),
        widget.child,
      ],
    );
  }

  Widget _buildDropdownUI(TribeTheme t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: t.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: t.isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matchedUsers.length,
          separatorBuilder: (_, __) => Divider(height: 0.5, thickness: 0.5, color: t.line),
          itemBuilder: (context, index) {
            final user = _matchedUsers[index];
            return InkWell(
              onTap: () => _onSelectUser(user),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Avatar(handle: user.handle ?? 'user', imageUrl: user.avatarUrl, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.displayName,
                            style: t.body(size: 14, weight: FontWeight.w600, color: t.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${user.handle ?? 'user'}',
                            style: t.caption(size: 12, color: t.inkFaint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
