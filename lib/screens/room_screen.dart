import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/participant_grid.dart';
import '../widgets/chat_panel.dart';
import '../config/app_theme.dart';
import 'evaluations_screen.dart';
import 'login_screen.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  bool _showChat = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final currentUser = provider.currentUser;
        if (currentUser == null) {
          return const LoginScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('LabStream'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    currentUser.role.displayName,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            actions: [
              // Participant count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.liveKitService.participants.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Microphone toggle
              IconButton(
                icon: Icon(
                  provider.liveKitService.localParticipant
                              ?.isMicrophoneEnabled() ==
                          true
                      ? Icons.mic
                      : Icons.mic_off,
                  size: 18,
                ),
                onPressed: provider.toggleMicrophone,
                tooltip: 'Toggle Microphone',
              ),

              // Screen share toggle
              IconButton(
                icon: Icon(
                  provider.liveKitService.localParticipant
                              ?.isScreenShareEnabled() ==
                          true
                      ? Icons.stop_screen_share
                      : Icons.screen_share,
                  size: 18,
                ),
                onPressed: provider.toggleScreenShare,
                tooltip: 'Toggle Screen Share',
              ),

              // Mute all (instructor only)
              if (provider.isInstructor)
                IconButton(
                  icon: const Icon(Icons.mic_off, size: 18),
                  onPressed: provider.muteAllParticipants,
                  tooltip: 'Mute All',
                ),

              // Evaluations (student only)
              if (provider.isStudent)
                IconButton(
                  icon: const Icon(Icons.assessment, size: 18),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EvaluationsScreen(),
                      ),
                    );
                  },
                  tooltip: 'My Evaluations',
                ),

              // Chat toggle
              IconButton(
                icon: Icon(
                  _showChat ? Icons.chat : Icons.chat_bubble_outline,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _showChat = !_showChat);
                },
                tooltip: 'Toggle Chat',
              ),

              const VerticalDivider(),

              // Leave room
              TextButton.icon(
                icon: const Icon(Icons.exit_to_app, size: 16),
                label: const Text('Leave'),
                onPressed: () => _handleLeave(context, provider),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              // Main content - Participant Grid
              Expanded(
                flex: _showChat ? 3 : 1,
                child: const ParticipantGrid(),
              ),

              // Chat Panel
              if (_showChat)
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.mediumGray,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: const ChatPanel(),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(provider),
        );
      },
    );
  }

  Widget? _buildBottomBar(AppProvider provider) {
    final error = provider.error;
    if (error == null) return null;

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.redAccent,
      child: Row(
        children: [
          const Icon(Icons.error, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
            onPressed: provider.clearError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLeave(BuildContext context, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room'),
        content: const Text('Are you sure you want to leave this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.leaveRoom();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }
}
