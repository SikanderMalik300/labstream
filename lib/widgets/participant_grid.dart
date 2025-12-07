import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/participant.dart';
import '../models/block.dart';
import '../providers/app_provider.dart';
import 'participant_tile.dart';
import 'evaluation_dialog.dart';
import 'block_dialog.dart';

class ParticipantGrid extends StatelessWidget {
  const ParticipantGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final participants = provider.liveKitService.participants;
        final isInstructor = provider.isInstructor;

        if (participants.isEmpty) {
          return const Center(
            child: Text('No participants yet'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return ParticipantTile(
              participant: participant,
              isInstructor: isInstructor,
              onTap: () => _handleParticipantTap(context, participant),
              onMute: isInstructor
                  ? () => _handleMute(context, provider, participant)
                  : null,
              onKick: isInstructor
                  ? () => _handleKick(context, provider, participant)
                  : null,
              onBlock: isInstructor
                  ? () => _handleBlock(context, provider, participant)
                  : null,
              onEvaluate: isInstructor
                  ? () => _handleEvaluate(context, provider, participant)
                  : null,
            );
          },
        );
      },
    );
  }

  void _handleParticipantTap(BuildContext context, ParticipantData participant) {
    // Show enlarged view of participant's screen if sharing
    if (participant.isSharingScreen) {
      showDialog(
        context: context,
        builder: (context) => _EnlargedScreenDialog(participant: participant),
      );
    }
  }

  Future<void> _handleMute(
    BuildContext context,
    AppProvider provider,
    ParticipantData participant,
  ) async {
    try {
      final participantSid = participant.liveKitParticipant?.sid;
      if (participantSid == null) return;

      await provider.muteParticipant(participantSid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Muted ${participant.fullName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mute: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleKick(
    BuildContext context,
    AppProvider provider,
    ParticipantData participant,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick Participant'),
        content: Text('Remove ${participant.fullName} from the session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kick'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final participantSid = participant.liveKitParticipant?.sid;
        if (participantSid == null) return;

        await provider.removeParticipant(participantSid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed ${participant.fullName}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to kick: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleBlock(
    BuildContext context,
    AppProvider provider,
    ParticipantData participant,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BlockDialog(participantName: participant.fullName),
    );

    if (result != null) {
      try {
        final participantSid = participant.liveKitParticipant?.sid;
        if (participantSid == null) return;

        await provider.blockParticipant(
          studentId: participant.id,
          participantSid: participantSid,
          duration: result['duration'] as BlockDuration,
          reason: result['reason'] as String?,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Blocked ${participant.fullName}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to block: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEvaluate(
    BuildContext context,
    AppProvider provider,
    ParticipantData participant,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EvaluationDialog(participant: participant),
    );

    if (result != null) {
      try {
        await provider.saveEvaluation(
          studentId: participant.id,
          score: result['score'] as double,
          notes: result['notes'] as String?,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved evaluation for ${participant.fullName}'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save evaluation: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}

class _EnlargedScreenDialog extends StatelessWidget {
  final ParticipantData participant;

  const _EnlargedScreenDialog({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
        child: Column(
          children: [
            AppBar(
              title: Text('${participant.fullName}\'s Screen'),
              automaticallyImplyLeading: true,
            ),
            Expanded(
              child: participant.screenTracks != null &&
                      participant.screenTracks!.isNotEmpty &&
                      participant.screenTracks!.first.track != null
                  ? VideoTrack(
                      participant.screenTracks!.first.track!,
                    )
                  : const Center(
                      child: Text('Screen share not available'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
