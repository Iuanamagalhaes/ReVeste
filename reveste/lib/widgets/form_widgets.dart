import 'package:flutter/material.dart';

class FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboard;

  const FormInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );
}

class FormDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const FormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(labelText: label),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      );
}

/// Miniatura de imagem com botão de remover.
class RemovableThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const RemovableThumb({super.key, required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
            Positioned(
              top: 2,
              right: 2,
              child: InkWell(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
}
