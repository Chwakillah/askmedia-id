import 'package:flutter/material.dart';

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const MarkdownText({
    super.key,
    required this.text,
    this.baseStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _parseMarkdown(text),
      style: baseStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextSpan _parseMarkdown(String text) {
    final List<InlineSpan> spans = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (i > 0) {
        spans.add(const TextSpan(text: '\n'));
      }
      
      // Check for heading
      if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: line.substring(2),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ));
        continue;
      }
      
      // Check for bullet list
      if (line.startsWith('- ')) {
        spans.add(const TextSpan(text: '• '));
        spans.addAll(_parseInlineMarkdown(line.substring(2)));
        continue;
      }
      
      // Check for numbered list
      final numberedListMatch = RegExp(r'^(\d+)\.\s').firstMatch(line);
      if (numberedListMatch != null) {
        spans.add(TextSpan(text: '${numberedListMatch.group(1)}. '));
        spans.addAll(_parseInlineMarkdown(line.substring(numberedListMatch.end)));
        continue;
      }
      
      // Parse inline markdown
      spans.addAll(_parseInlineMarkdown(line));
    }
    
    return TextSpan(children: spans);
  }

  List<InlineSpan> _parseInlineMarkdown(String text) {
    final List<InlineSpan> spans = [];
    int currentIndex = 0;
    
    // Patterns: bold (**), italic (*), underline (__), code (`)
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|__(.+?)__|`(.+?)`');
    
    for (final match in pattern.allMatches(text)) {
      // Add text before match
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      
      // Add formatted text
      if (match.group(1) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null) {
        // Underline
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(decoration: TextDecoration.underline),
        ));
      } else if (match.group(4) != null) {
        // Code
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey[200],
            fontSize: 13,
          ),
        ));
      }
      
      currentIndex = match.end;
    }
    
    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }
    
    return spans;
  }
}