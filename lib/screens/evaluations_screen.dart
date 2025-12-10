import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/evaluation.dart';
import '../config/app_theme.dart';

class EvaluationsScreen extends StatefulWidget {
  const EvaluationsScreen({super.key});

  @override
  State<EvaluationsScreen> createState() => _EvaluationsScreenState();
}

class _EvaluationsScreenState extends State<EvaluationsScreen> {
  List<Evaluation>? _evaluations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
    // Set up periodic refresh to check for new evaluations
    Future.delayed(const Duration(seconds: 2), _setupAutoRefresh);
  }

  void _setupAutoRefresh() {
    if (!mounted) return;
    // Refresh evaluations every 5 seconds for real-time updates
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadEvaluations();
        _setupAutoRefresh();
      }
    });
  }

  @override
  void dispose() {
    // Clean up is handled by mounted check
    super.dispose();
  }

  Future<void> _loadEvaluations() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();

      // Check if user is logged in
      if (provider.currentUser == null) {
        throw Exception('User not logged in');
      }

      final evaluations = await provider.getStudentEvaluations();

      if (mounted) {
        setState(() {
          _evaluations = evaluations ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading evaluations: $e');
      if (mounted) {
        setState(() {
          _evaluations = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load evaluations: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Evaluations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _evaluations == null || _evaluations!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.assessment,
                        size: 64,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No evaluations yet',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _evaluations!.length,
                  itemBuilder: (context, index) {
                    return _EvaluationCard(
                      evaluation: _evaluations![index],
                    );
                  },
                ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final Evaluation evaluation;

  const _EvaluationCard({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Session: ${evaluation.sessionId.substring(0, 8)}...',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(evaluation.grade),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    evaluation.grade,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Score
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: AppTheme.lightGray),
                const SizedBox(width: 4),
                Text(
                  'Score: ${evaluation.score.toStringAsFixed(1)} / 10.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppTheme.lightGray),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(evaluation.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),

            // Notes
            if (evaluation.notes != null && evaluation.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Notes:',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                evaluation.notes!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return const Color(0xFFE0E0E0);
      case 'B':
        return const Color(0xFFC0C0C0);
      case 'C':
        return const Color(0xFFA0A0A0);
      case 'D':
        return const Color(0xFF808080);
      case 'E':
        return const Color(0xFF606060);
      default:
        return const Color(0xFF404040);
    }
  }
}
