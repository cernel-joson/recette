import 'package:flutter/material.dart';
import 'package:recette/features/recipes/data/models/models.dart';

/// A dialog for editing the details of a single TimingInfo object.
class TimingInfoEditDialog extends StatefulWidget {
  final TimingInfo? timingInfo;

  const TimingInfoEditDialog({super.key, this.timingInfo});

  @override
  State<TimingInfoEditDialog> createState() => _TimingInfoEditDialogState();
}

class _TimingInfoEditDialogState extends State<TimingInfoEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.timingInfo?.label ?? '');
    _durationController = TextEditingController(text: widget.timingInfo?.duration ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final updatedTimingInfo = TimingInfo(
        label: _labelController.text,
        duration: _durationController.text,
      );
      Navigator.of(context).pop(updatedTimingInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.timingInfo == null ? 'Add Timing' : 'Edit Timing'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label (e.g., Rest Time)'),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a label' : null,
            ),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration (e.g., 10 mins)'),
               validator: (value) =>
                  value!.isEmpty ? 'Please enter a duration' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
