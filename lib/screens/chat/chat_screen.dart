import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasMarkedRead = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markAsRead() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null && !_hasMarkedRead) {
      _hasMarkedRead = true;
      ref.read(firestoreServiceProvider).markMessagesAsRead(
            widget.chatId,
            currentUser.uid,
            widget.otherUserId,
          );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    _messageController.clear();

    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: currentUser.uid,
      senderName: currentUser.displayName,
      text: text,
      type: 'text',
      status: 'sent',
      readBy: [],
      timestamp: DateTime.now(),
    );

    // Update locally or let Firestore handle it
    await ref.read(firestoreServiceProvider).sendMessage(
          widget.chatId,
          message,
          currentUser.uid,
          widget.otherUserId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final messagesAsyncValue = ref.watch(chatMessagesProvider(widget.chatId));

    // Mark as read once when messages load
    messagesAsyncValue.whenData((_) => _markAsRead());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.otherUserPhoto != null
                        ? NetworkImage(widget.otherUserPhoto!)
                        : null,
                    child: widget.otherUserPhoto == null
                        ? Text(widget.otherUserName[0])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(widget.otherUserName),
                ],
              ),
            ),
          ),
        ),
      ),
      body: AnimatedGradientBg(
        child: Column(
          children: [
            Expanded(
              child: messagesAsyncValue.when(
                data: (messages) {
                  return ListView.builder(
                    reverse: true, // Show latest at bottom
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 100, bottom: 20, left: 16, right: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUser?.uid;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(5),
                  bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message.text ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : (AppColors.isDarkMode(context) ? Colors.white : Colors.black),
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 4),
                  _buildReadReceiptIcon(message.status),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadReceiptIcon(String status) {
    switch (status) {
      case 'read':
        // Blue double check
        return const Icon(Icons.done_all, size: 14, color: Colors.blueAccent);
      case 'delivered':
        // Grey double check
        return Icon(Icons.done_all, size: 14, color: Colors.grey[400]);
      case 'sent':
      default:
        // Single grey check
        return Icon(Icons.check, size: 14, color: Colors.grey[400]);
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera),
              onPressed: () {
                // TODO: Implement image upload
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
