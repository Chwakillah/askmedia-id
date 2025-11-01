import 'package:flutter/material.dart';
import '../themes/app_collors.dart';

class RichTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final String hintText;

  const RichTextEditor({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 6,
    this.hintText = 'Tulis sesuatu...',
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.inputBackground.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildToolbar(),
              const Divider(height: 1),
              TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                validator: widget.validator,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Gunakan markdown: **bold**, *italic*, __underline__, - list, 1. numbered',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarButton(
              icon: Icons.format_bold,
              label: 'Bold',
              onPressed: () => _insertMarkdown('**', '**'),
            ),
            _buildToolbarButton(
              icon: Icons.format_italic,
              label: 'Italic',
              onPressed: () => _insertMarkdown('*', '*'),
            ),
            _buildToolbarButton(
              icon: Icons.format_underlined,
              label: 'Underline',
              onPressed: () => _insertMarkdown('__', '__'),
            ),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 4),
            _buildToolbarButton(
              icon: Icons.format_list_bulleted,
              label: 'List',
              onPressed: () => _insertLinePrefix('- '),
            ),
            _buildToolbarButton(
              icon: Icons.format_list_numbered,
              label: 'Numbered',
              onPressed: () => _insertLinePrefix('1. '),
            ),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 4),
            _buildToolbarButton(
              icon: Icons.title,
              label: 'Heading',
              onPressed: () => _insertLinePrefix('# '),
            ),
            _buildToolbarButton(
              icon: Icons.code,
              label: 'Code',
              onPressed: () => _insertMarkdown('`', '`'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: label,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 20,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    if (selection.isValid) {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
      );
    } else {
      final cursorPos = selection.baseOffset;
      final newText = text.substring(0, cursorPos) + 
                      prefix + 
                      'text' + 
                      suffix + 
                      text.substring(cursorPos);
      
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: cursorPos + prefix.length,
        ),
      );
    }
    
    _focusNode.requestFocus();
  }

  void _insertLinePrefix(String prefix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursorPos = selection.baseOffset;
    
    // Find the start of the current line
    int lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;
    
    final newText = text.substring(0, lineStart) + 
                    prefix + 
                    text.substring(lineStart);
    
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: cursorPos + prefix.length,
      ),
    );
    
    _focusNode.requestFocus();
  }
}