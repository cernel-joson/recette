import 'package:flutter/material.dart';

class CustomChipInput extends StatefulWidget {
  final List<String> initialChips;
  final ValueChanged<List<String>> onChipsChanged;
  final String label;

  const CustomChipInput({
    super.key,
    required this.initialChips,
    required this.onChipsChanged,
    this.label = 'Add tags',
  });

  @override
  State<CustomChipInput> createState() => _CustomChipInputState();
}

class _CustomChipInputState extends State<CustomChipInput> {
  late List<String> _chips;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chips = List<String>.from(widget.initialChips);
  }

  void _addChip(String text) {
    text = text.trim().toLowerCase();
    if (text.isNotEmpty && !_chips.contains(text)) {
      setState(() {
        _chips.add(text);
      });
      _textController.clear();
      widget.onChipsChanged(_chips);
    }
  }

  void _removeChip(String chip) {
    setState(() {
      _chips.remove(chip);
    });
    widget.onChipsChanged(_chips);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: _addChip,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _chips.map((chip) {
            return Chip(
              label: Text(chip),
              onDeleted: () => _removeChip(chip),
            );
          }).toList(),
        ),
      ],
    );
  }
}