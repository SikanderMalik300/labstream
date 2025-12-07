import 'package:flutter/material.dart';
import '../models/participant.dart';
import '../config/app_config.dart';

class EvaluationDialog extends StatefulWidget {
  final ParticipantData participant;

  const EvaluationDialog({super.key, required this.participant});

  @override
  State<EvaluationDialog> createState() => _EvaluationDialogState();
}

class _EvaluationDialogState extends State<EvaluationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  double _score = 5.0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'score': _score,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Evaluate ${widget.participant.fullName}'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info
              Text(
                'ID: ${widget.participant.universityId ?? 'N/A'}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Score Slider
              Text('Score: ${_score.toStringAsFixed(1)}', style: theme.textTheme.titleMedium),
              Slider(
                value: _score,
                min: AppConfig.minScore,
                max: AppConfig.maxScore,
                divisions: 100,
                label: _score.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _score = value);
                },
              ),
              const SizedBox(height: 8),

              // Grade indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0.0', style: theme.textTheme.bodySmall),
                  Text(
                    _getGrade(_score),
                    style: theme.textTheme.titleLarge,
                  ),
                  Text('10.0', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add evaluation notes...',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getGrade(double score) {
    if (score >= 9.0) return 'A';
    if (score >= 8.0) return 'B';
    if (score >= 7.0) return 'C';
    if (score >= 6.0) return 'D';
    if (score >= 5.0) return 'E';
    return 'F';
  }
}
