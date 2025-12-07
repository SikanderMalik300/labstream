import 'package:flutter/material.dart';
import '../models/block.dart';

class BlockDialog extends StatefulWidget {
  final String participantName;

  const BlockDialog({super.key, required this.participantName});

  @override
  State<BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<BlockDialog> {
  final _reasonController = TextEditingController();
  BlockDuration _selectedDuration = BlockDuration.minutes10;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleBlock() {
    Navigator.of(context).pop({
      'duration': _selectedDuration,
      'reason': _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Block ${widget.participantName}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select block duration:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Duration options
            RadioListTile<BlockDuration>(
              title: const Text('10 Minutes'),
              value: BlockDuration.minutes10,
              groupValue: _selectedDuration,
              onChanged: (value) {
                setState(() => _selectedDuration = value!);
              },
              dense: true,
            ),
            RadioListTile<BlockDuration>(
              title: const Text('30 Minutes'),
              value: BlockDuration.minutes30,
              groupValue: _selectedDuration,
              onChanged: (value) {
                setState(() => _selectedDuration = value!);
              },
              dense: true,
            ),
            RadioListTile<BlockDuration>(
              title: const Text('Permanent'),
              value: BlockDuration.permanent,
              groupValue: _selectedDuration,
              onChanged: (value) {
                setState(() => _selectedDuration = value!);
              },
              dense: true,
            ),
            const SizedBox(height: 16),

            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Enter reason for blocking...',
              ),
              maxLines: 2,
              maxLength: 200,
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
          onPressed: _handleBlock,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          child: const Text('Block'),
        ),
      ],
    );
  }
}
