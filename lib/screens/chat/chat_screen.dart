import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:entangled/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';
import '../../widgets/holographic_avatar.dart';
import '../../widgets/lifeline_monitor.dart';

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
  bool _isTyping = false;
  Timer? _typingTimer;
  final Set<String> _selectedMessageIds = {};
  MessageModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _setTypingStatus(false);
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _setTypingStatus(true);
    } else if (_messageController.text.isEmpty && _isTyping) {
      _setTypingStatus(false);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) _setTypingStatus(false);
    });
  }

  void _setTypingStatus(bool isTyping) {
    if (_isTyping == isTyping) return;
    setState(() => _isTyping = isTyping);

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      ref
          .read(firestoreServiceProvider)
          .setTypingStatus(widget.chatId, currentUser.uid, isTyping);
    }
  }

  void _markAsRead() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      ref
          .read(firestoreServiceProvider)
          .markMessagesAsRead(
            widget.chatId,
            currentUser.uid,
            widget.otherUserId,
          );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _replyingTo == null) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final textToSend = text;
    final replyData = _replyingTo != null
        ? {
            'id': _replyingTo!.id,
            'text': _replyingTo!.text ?? '📷 Image',
            'senderId': _replyingTo!.senderId,
            'senderName': _replyingTo!.senderName,
          }
        : null;

    _messageController.clear();
    setState(() => _replyingTo = null); // Clear reply state
    _setTypingStatus(false);

    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: currentUser.uid,
      senderName: currentUser.displayName,
      text: textToSend,
      type: 'text',
      status: 'sent',
      readBy: [],
      replyTo: replyData,
      timestamp: DateTime.now(),
    );

    await ref
        .read(firestoreServiceProvider)
        .sendMessage(
          widget.chatId,
          message,
          currentUser.uid,
          widget.otherUserId,
        );
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  Future<void> _deleteSelectedMessages() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final messages = ref.read(chatMessagesProvider(widget.chatId)).value ?? [];
    final selectedMsgs = messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();

    final allMine = selectedMsgs.every((m) => m.senderId == currentUser.uid);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.obsidianBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        title: Text(
          'Delete Message',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          selectedMsgs.length == 1
              ? 'Are you sure you want to delete this message?'
              : 'Are you sure you want to delete these ${selectedMsgs.length} messages?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(firestoreServiceProvider);
              for (var id in _selectedMessageIds) {
                await service.deleteMessageForMe(
                  widget.chatId,
                  id,
                  currentUser.uid,
                );
              }
              _cancelSelection();
            },
            child: Text(
              'Delete for me',
              style: GoogleFonts.outfit(color: AppColors.electricRose),
            ),
          ),
          if (allMine)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final service = ref.read(firestoreServiceProvider);
                for (var id in _selectedMessageIds) {
                  await service.deleteMessageForAll(widget.chatId, id);
                }
                _cancelSelection();
              },
              child: Text(
                'Delete for everyone',
                style: GoogleFonts.outfit(
                  color: AppColors.electricRose,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    // Show a temporary snackbar or indicator if needed, but we'll rely on the stream
    final storageService = ref.read(storageServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    final imageUrl = await storageService.uploadChatMessageImage(
      widget.chatId,
      File(pickedFile.path),
    );

    if (imageUrl != null) {
      final message = MessageModel(
        id: const Uuid().v4(),
        senderId: currentUser.uid,
        senderName: currentUser.displayName,
        imageUrl: imageUrl,
        type: 'image',
        status: 'sent',
        readBy: [],
        timestamp: DateTime.now(),
      );

      await firestoreService.sendMessage(
        widget.chatId,
        message,
        currentUser.uid,
        widget.otherUserId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final messagesAsyncValue = ref.watch(chatMessagesProvider(widget.chatId));
    final chatDocAsyncValue = ref.watch(chatProvider(widget.chatId));

    // Mark as read whenever new messages load/arrive
    messagesAsyncValue.whenData((messages) {
      if (messages.isNotEmpty &&
          messages.first.senderId == widget.otherUserId) {
        _markAsRead();
      }
    });

    final isOtherUserTyping = chatDocAsyncValue.when(
      data: (chat) => chat?.typingUsers.contains(widget.otherUserId) ?? false,
      loading: () => false,
      error: (error, stackTrace) => false,
    );

    final isSelectionMode = _selectedMessageIds.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: AppBar(
              backgroundColor: isSelectionMode
                  ? AppColors.radiantViolet.withAlpha(51)
                  : Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  isSelectionMode
                      ? Icons.close_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: isSelectionMode ? 24 : 20,
                ),
                onPressed: isSelectionMode
                    ? _cancelSelection
                    : () => Navigator.pop(context),
              ),
              title: isSelectionMode
                  ? Text(
                      '${_selectedMessageIds.length} selected',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  : Row(
                      children: [
                        HolographicAvatar(
                          uid: widget.otherUserId,
                          radius: 18,
                          fallbackPhotoUrl: widget.otherUserPhoto,
                          fallbackName: widget.otherUserName,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.otherUserName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (isSelectionMode)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.electricRose,
                    ),
                    onPressed: _deleteSelectedMessages,
                  ),
              ],
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
                    padding: const EdgeInsets.only(
                      top: 100,
                      bottom: 20,
                      left: 16,
                      right: 16,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUser?.uid;
                      return _buildMessageBubble(msg, isMe, currentUser);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
            LifelineMonitor(isTyping: isOtherUserTyping),
            _buildMessageInput(isOtherUserTyping, currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    bool isMe,
    UserModel? currentUser,
  ) {
    final isSelected = _selectedMessageIds.contains(message.id);
    final isSelectionMode = _selectedMessageIds.isNotEmpty;

    return SwipeToReplyWrapper(
      onReply: () {
        if (!message.isDeleted) {
          setState(() => _replyingTo = message);
        }
      },
      child: GestureDetector(
        onLongPress: () => _toggleMessageSelection(message.id),
        onTap: () {
          if (isSelectionMode) {
            _toggleMessageSelection(message.id);
          }
        },
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.radiantViolet.withAlpha(38)
                : Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe) ...[
                    HolographicAvatar(
                      uid: widget.otherUserId,
                      radius: 14,
                      fallbackPhotoUrl: widget.otherUserPhoto,
                      fallbackName: widget.otherUserName,
                      showGlow: false,
                      heroTag: null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      padding: message.type == 'image'
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                      decoration: BoxDecoration(
                        color: message.isDeleted
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white10
                                  : Colors.black12)
                            : (isMe
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withAlpha(46)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.primary.withAlpha(31))
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withAlpha(20)
                                        : Colors.black.withAlpha(20))),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                        boxShadow: isMe && !message.isDeleted
                            ? [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(31),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                        border:
                            !isMe &&
                                !message.isDeleted &&
                                Theme.of(context).brightness == Brightness.light
                            ? Border.all(color: Colors.black.withAlpha(13))
                            : null,
                      ),
                      child: message.isDeleted
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.block_flipped,
                                    size: 14,
                                    color: Colors.white.withAlpha(128),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'This message was deleted',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withAlpha(128),
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Quoted Reply Preview
                                if (message.replyTo != null) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(38),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border(
                                        left: BorderSide(
                                          color: isMe
                                              ? Colors.white70
                                              : AppColors.radiantViolet,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.replyTo!['senderId'] ==
                                                  currentUser?.uid
                                              ? 'You'
                                              : (message.replyTo!['senderName'] ??
                                                    'Unknown'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isMe
                                                ? Colors.white
                                                : AppColors.radiantViolet,
                                          ),
                                        ),
                                        Text(
                                          message.replyTo!['text'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            color: isMe
                                                ? Colors.white.withAlpha(204)
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (message.type == 'image' &&
                                    message.imageUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(
                                      imageUrl: message.imageUrl!,
                                      placeholder: (context, url) => Container(
                                        height: 200,
                                        width: 200,
                                        color: AppColors.obsidianBase,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 2.0),
                                    child: Text(
                                      message.text ?? '',
                                      style: GoogleFonts.outfit(
                                        color: isMe
                                            ? (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface)
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                _buildMetadata(message, isMe),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
      ),
    );
  }

  Widget _buildMetadata(
    MessageModel message,
    bool isMe, {
    bool onImage = false,
  }) {
    final textColor = onImage
        ? Colors.white.withAlpha(230)
        : (isMe
              ? Colors.white.withAlpha(179)
              : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(179));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: GoogleFonts.outfit(
            fontSize: 9,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.status == 'read'
                ? Icons.done_all_rounded
                : message.status == 'delivered'
                ? Icons.done_all_rounded
                : Icons.check_rounded,
            size: 11,
            color: message.status == 'read'
                ? const Color.fromARGB(255, 0, 204, 255)
                : textColor,
          ),
        ],
      ],
    );
  }

  Widget _buildMessageInput(bool isOtherUserTyping, UserModel? currentUser) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder.withAlpha(26)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.glassHeavy,
                      border: Border.all(color: AppColors.glassBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.radiantViolet,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _replyingTo!.senderId == currentUser?.uid
                                    ? 'You'
                                    : _replyingTo!.senderName,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.radiantViolet,
                                ),
                              ),
                              Text(
                                _replyingTo!.text ?? '📷 Image',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() => _replyingTo = null),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.glassBase,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.glassBase,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.add_rounded,
                          size: 24,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: _sendImage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: 200.ms,
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.radiantViolet,
                            AppColors.electricRose,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.radiantViolet.withAlpha(77),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const SwipeToReplyWrapper({
    super.key,
    required this.child,
    required this.onReply,
  });

  @override
  State<SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  final double _threshold = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Only allow right swipe
    if (details.delta.dx < 0 && _dragOffset <= 0) return;

    setState(() {
      _dragOffset += details.delta.dx * 0.6; // Slack factor
      if (_dragOffset < 0) _dragOffset = 0;
      if (_dragOffset > 100) _dragOffset = 100; // Cap
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset >= _threshold) {
      widget.onReply();
    }

    _animation =
        Tween<double>(begin: _dragOffset, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        )..addListener(() {
          setState(() {
            _dragOffset = _animation.value;
          });
        });

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // Reply Icon underneath
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: (_dragOffset / _threshold).clamp(0.0, 1.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.radiantViolet.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.reply_rounded,
                  color: AppColors.radiantViolet,
                  size: 20,
                ),
              ),
            ),
          ),
          // Content
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
