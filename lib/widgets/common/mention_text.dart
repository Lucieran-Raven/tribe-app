import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MentionText extends StatelessWidget {
  final String content;
  final TextStyle style;
  final TextStyle mentionStyle;
  final Function(String handle)? onMentionTap;

  const MentionText({
    super.key,
    required this.content,
    required this.style,
    required this.mentionStyle,
    this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use RegExp to find all @mentions
    final regex = RegExp(r'@([a-zA-Z0-9_]+)');
    final matches = regex.allMatches(content);
    
    if (matches.isEmpty) {
      return Text(content, style: style);
    }

    // Build TextSpan list
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      // Add normal text before the mention
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: style,
        ));
      }

      // Add the mention with tap gesture
      final handle = match.group(1) ?? '';
      spans.add(TextSpan(
        text: '@$handle',
        style: mentionStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onMentionTap != null) {
              onMentionTap!(handle);
            }
          },
      ));

      lastIndex = match.end;
    }

    // Add remaining text after the last mention
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }
}
