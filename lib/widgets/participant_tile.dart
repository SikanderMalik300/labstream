import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../models/participant.dart';
import '../config/app_theme.dart';
import 'video_renderer.dart';

class ParticipantTile extends StatelessWidget {
  final ParticipantData participant;
  final bool isInstructor;
  final VoidCallback? onTap;
  final VoidCallback? onMute;
  final VoidCallback? onKick;
  final VoidCallback? onBlock;
  final VoidCallback? onEvaluate;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.isInstructor = false,
    this.onTap,
    this.onMute,
    this.onKick,
    this.onBlock,
    this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkGray,
          border: Border.all(
            color: participant.hasHandRaised
                ? AppTheme.primaryWhite
                : AppTheme.mediumGray,
            width: participant.hasHandRaised ? 2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video/Screen Share Area
            Expanded(
              child: Stack(
                children: [
                  // Video or placeholder
                  Container(
                    color: AppTheme.primaryBlack,
                    child: Center(
                      child: participant.isSharingScreen
                          ? _buildScreenShareView()
                          : Icon(
                              Icons.person,
                              size: 32,
                              color: AppTheme.mediumGray,
                            ),
                    ),
                  ),

                  // Status indicators
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (participant.isSharingScreen)
                          _buildStatusBadge(Icons.screen_share, AppTheme.accentBlue),
                        if (participant.isAudioMuted)
                          _buildStatusBadge(Icons.mic_off, AppTheme.accentRed),
                        if (participant.hasHandRaised)
                          _buildStatusBadge(Icons.pan_tool, AppTheme.primaryWhite),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Participant Info
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          participant.fullName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (participant.isInstructor)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.mediumGray,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'INST',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                  if (participant.studentId != null || participant.instructorId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      participant.isStudent
                        ? 'Student ID: ${participant.studentId}'
                        : 'Instructor ID: ${participant.instructorId}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Instructor Controls
            if (isInstructor && participant.isStudent)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: Wrap(
                  spacing: 4,
                  children: [
                    _buildControlButton(
                      icon: participant.isAudioMuted ? Icons.mic_off : Icons.mic,
                      label: 'Mute',
                      onPressed: onMute,
                    ),
                    _buildControlButton(
                      icon: Icons.remove_circle_outline,
                      label: 'Kick',
                      onPressed: onKick,
                    ),
                    _buildControlButton(
                      icon: Icons.block,
                      label: 'Block',
                      onPressed: onBlock,
                    ),
                    _buildControlButton(
                      icon: Icons.edit,
                      label: 'Score',
                      onPressed: onEvaluate,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenShareView() {
    // This will render the actual screen share when available
    final screenTracks = participant.screenTracks;
    if (screenTracks == null || screenTracks.isEmpty) {
      return const Center(
        child: Icon(Icons.screen_share, size: 48, color: AppTheme.lightGray),
      );
    }

    final track = screenTracks.first.track;
    if (track == null) {
      return const Center(
        child: Icon(Icons.screen_share, size: 48, color: AppTheme.lightGray),
      );
    }

    return VideoRenderer(
      track,
      fit: BoxFit.contain,
    );
  }

  Widget _buildStatusBadge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 2),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Icon(icon, size: 12, color: AppTheme.primaryWhite),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 20,
      child: TextButton.icon(
        icon: Icon(icon, size: 10),
        label: Text(label, style: const TextStyle(fontSize: 9)),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
