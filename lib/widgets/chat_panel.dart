import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../providers/app_provider.dart';
import '../config/app_theme.dart';

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(AppProvider provider) {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    provider.sendChatMessage(message);
    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final messages = provider.chatService.messages;
        final raisedHandsCount = provider.chatService.raisedHandsCount;

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkGray,
                border: Border(
                  bottom: BorderSide(color: AppTheme.mediumGray, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Text('Chat', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  if (raisedHandsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pan_tool,
                            size: 12,
                            color: AppTheme.primaryBlack,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$raisedHandsCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _MessageBubble(message: messages[index]);
                      },
                    ),
            ),

            // Hand raise button (students only)
            if (provider.isStudent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.mediumGray, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.pan_tool, size: 14),
                        label: Text(
                          provider.chatService.raisedHands
                                  .contains(provider.currentUser?.id)
                              ? 'Lower Hand'
                              : 'Raise Hand',
                        ),
                        onPressed: () {
                          if (provider.chatService.raisedHands
                              .contains(provider.currentUser?.id)) {
                            provider.lowerHand();
                          } else {
                            provider.raiseHand();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Message input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.mediumGray, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        isDense: true,
                      ),
                      maxLength: 500,
                      buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          maxLength}) {
                        return null; // Hide counter
                      },
                      onSubmitted: (_) => _sendMessage(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, size: 18),
                    onPressed: () => _sendMessage(provider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                message.senderName,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: message.isFromInstructor
                      ? AppTheme.primaryWhite
                      : AppTheme.lightGray,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                timeFormat.format(message.timestamp),
                style: theme.textTheme.labelSmall,
              ),
              if (message.isHandRaise) ...[
                const SizedBox(width: 4),
                const Icon(Icons.pan_tool, size: 10, color: AppTheme.primaryWhite),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            message.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle:
                  message.isSystemMessage ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
