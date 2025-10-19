import 'package:flutter/material.dart';
import '../themes/app_collors.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;

  const CustomInputField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused 
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              validator: widget.validator,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: widget.hint ?? "Masukkan ${widget.label.toLowerCase()}",
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                ),
                prefixIcon: widget.icon != null
                    ? Icon(
                        widget.icon,
                        color: _isFocused ? AppColors.primary : Colors.grey[600],
                        size: 22,
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.icon != null ? 16 : 20,
                  vertical: widget.maxLines == 1 ? 18 : 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}