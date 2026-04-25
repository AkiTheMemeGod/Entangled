import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:entangled/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/audio_player_widget.dart';
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
  static const List<String> _reactionEmojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;
  final Set<String> _selectedMessageIds = {};
  MessageModel? _replyingTo;
  String? _replyingPreviewText;
  bool _isUploadingImages = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecordingVoice = false;
  bool _isUploadingVoice = false;
  DateTime? _recordingStartedAt;
  Offset? _lastReactionTapPosition;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _setTypingStatus(false);
    _typingTimer?.cancel();
    _audioRecorder.dispose();
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
            'text': _replyingPreviewText ?? _replyingTo!.text ?? '📷 Image',
            'senderId': _replyingTo!.senderId,
            'senderName': _replyingTo!.senderName,
          }
        : null;

    _messageController.clear();
    setState(() {
      _replyingTo = null;
      _replyingPreviewText = null;
    }); // Clear reply state
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

  Future<void> _toggleReaction(MessageModel message, String emoji) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || message.isDeleted) return;

    try {
      await ref
          .read(firestoreServiceProvider)
          .toggleMessageReaction(
            chatId: widget.chatId,
            messageId: message.id,
            emoji: emoji,
            userId: currentUser.uid,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update reaction. Please try again.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }

  bool _didUserReact(MessageModel message, String uid) {
    for (final users in message.reactions.values) {
      if (users.contains(uid)) return true;
    }
    return false;
  }

  Future<void> _showReactionPicker(
    MessageModel message, {
    Offset? anchor,
  }) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || message.isDeleted) return;

    final size = MediaQuery.of(context).size;
    const pickerWidth = 286.0;
    final safeTop = MediaQuery.of(context).padding.top + 10;
    final target = anchor ?? Offset(size.width / 2, size.height / 2);
    final top = (target.dy - 72).clamp(safeTop, size.height - 110).toDouble();
    final left = (target.dx - (pickerWidth / 2))
        .clamp(10.0, size.width - pickerWidth - 10)
        .toDouble();

    final selectedEmoji = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: 'Message reactions',
      transitionDuration: const Duration(milliseconds: 130),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  behavior: HitTestBehavior.opaque,
                ),
              ),
              Positioned(
                top: top,
                left: left,
                child:
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22282C),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withAlpha(24),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _reactionEmojis.map((emoji) {
                              final isActive =
                                  message.reactions[emoji]?.contains(
                                    currentUser.uid,
                                  ) ??
                                  false;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(emoji),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white.withAlpha(26)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                        .animate()
                        .scale(
                          begin: const Offset(0.92, 0.92),
                          duration: 120.ms,
                        )
                        .fadeIn(duration: 120.ms),
              ),
            ],
          ),
        );
      },
    );

    if (selectedEmoji == null) return;
    await _toggleReaction(message, selectedEmoji);
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

  Future<void> _sendImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (pickedFiles.isEmpty) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final storageService = ref.read(storageServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    var sentCount = 0;

    if (mounted) setState(() => _isUploadingImages = true);

    try {
      for (final pickedFile in pickedFiles) {
        final imageUrl = await storageService.uploadChatMessageImage(
          widget.chatId,
          File(pickedFile.path),
        );

        if (imageUrl == null) continue;

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
        sentCount++;
      }
    } finally {
      if (mounted) setState(() => _isUploadingImages = false);
    }

    if (mounted && sentCount != pickedFiles.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sent $sentCount of ${pickedFiles.length} images',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }

  String _voiceReplyPreview() => '🎤 Voice note';

  Future<void> _startVoiceRecording() async {
    if (_isRecordingVoice || _isUploadingVoice || _isUploadingImages) return;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Microphone permission is required to record voice notes.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _isRecordingVoice = true;
        _recordingStartedAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not start voice recording.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }

  Future<void> _stopAndSendVoiceRecording() async {
    if (!_isRecordingVoice || _isUploadingVoice) return;

    final startedAt = _recordingStartedAt;
    String? audioPath;
    try {
      audioPath = await _audioRecorder.stop();
    } finally {
      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _recordingStartedAt = null;
        });
      }
    }

    if (audioPath == null) return;

    final durationMs = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inMilliseconds;

    if (durationMs != null && durationMs < 600) {
      try {
        await File(audioPath).delete();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice note is too short.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
      return;
    }

    await _sendVoiceMessage(audioPath, durationMs);
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_isRecordingVoice || _isUploadingVoice) return;

    String? audioPath;
    try {
      audioPath = await _audioRecorder.stop();
    } finally {
      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _recordingStartedAt = null;
        });
      }
    }

    if (audioPath != null) {
      try {
        await File(audioPath).delete();
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice note discarded.', style: GoogleFonts.outfit()),
      ),
    );
  }

  Future<void> _sendVoiceMessage(String audioPath, int? durationMs) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final storageService = ref.read(storageServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final replyData = _replyingTo != null
        ? {
            'id': _replyingTo!.id,
            'text': _replyingPreviewText ?? _replyingTo!.text ?? '📷 Image',
            'senderId': _replyingTo!.senderId,
            'senderName': _replyingTo!.senderName,
          }
        : null;

    if (mounted) {
      setState(() {
        _isUploadingVoice = true;
      });
    }

    try {
      final audioUrl = await storageService.uploadChatAudio(
        widget.chatId,
        File(audioPath),
      );

      if (audioUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload voice note.',
              style: GoogleFonts.outfit(),
            ),
          ),
        );
        return;
      }

      final message = MessageModel(
        id: const Uuid().v4(),
        senderId: currentUser.uid,
        senderName: currentUser.displayName,
        audioUrl: audioUrl,
        audioDurationMs: durationMs,
        type: 'audio',
        status: 'sent',
        readBy: [],
        replyTo: replyData,
        timestamp: DateTime.now(),
      );

      await firestoreService.sendMessage(
        widget.chatId,
        message,
        currentUser.uid,
        widget.otherUserId,
      );

      if (mounted) {
        setState(() {
          _replyingTo = null;
          _replyingPreviewText = null;
        });
      }
      _setTypingStatus(false);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingVoice = false;
        });
      }
      try {
        await File(audioPath).delete();
      } catch (_) {}
    }
  }

  bool _isImageMessage(MessageModel message) {
    return message.type == 'image' &&
        message.imageUrl != null &&
        !message.isDeleted;
  }

  String _replyPreviewTextForMessage(
    MessageModel message,
    int imageBatchCount,
  ) {
    if (message.type == 'audio') {
      return _voiceReplyPreview();
    }
    if (_isImageMessage(message)) {
      if (imageBatchCount > 1) {
        return '$imageBatchCount images';
      }
      return '📷 Image';
    }
    return message.text ?? '';
  }

  bool _canGroupTogether(MessageModel newer, MessageModel older) {
    if (!_isImageMessage(newer) || !_isImageMessage(older)) return false;
    if (newer.senderId != older.senderId) return false;
    final diff = newer.timestamp.difference(older.timestamp).abs();
    return diff <= const Duration(minutes: 2);
  }

  bool _isGroupedImageContinuation(List<MessageModel> messages, int index) {
    if (index <= 0 || index >= messages.length) return false;
    final previous = messages[index - 1];
    final current = messages[index];
    return _canGroupTogether(previous, current);
  }

  List<MessageModel> _collectImageGroup(
    List<MessageModel> messages,
    int startIndex,
  ) {
    final group = <MessageModel>[];
    if (startIndex < 0 || startIndex >= messages.length) return group;

    final first = messages[startIndex];
    if (!_isImageMessage(first)) return group;

    group.add(first);
    for (var i = startIndex + 1; i < messages.length; i++) {
      final candidate = messages[i];
      if (_canGroupTogether(group.last, candidate)) {
        group.add(candidate);
      } else {
        break;
      }
    }
    return group;
  }

  List<String> _allChatImageUrls(List<MessageModel> messages) {
    final urls = <String>[];
    for (final message in messages.reversed) {
      if (_isImageMessage(message)) {
        urls.add(message.imageUrl!);
      }
    }
    return urls;
  }

  void _openImageViewer(List<MessageModel> allMessages, String initialUrl) {
    final urls = _allChatImageUrls(allMessages);
    if (urls.isEmpty) return;
    final initialIndex = max(0, urls.indexOf(initialUrl));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChatImageGalleryScreen(
          imageUrls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildGroupedImageContent({
    required List<MessageModel> group,
    required List<MessageModel> allMessages,
    required bool isSelectionMode,
  }) {
    final urls = group.map((m) => m.imageUrl!).toList();
    final visibleCount = min(4, urls.length);

    if (visibleCount == 1) {
      return GestureDetector(
        onTap: isSelectionMode
            ? null
            : () => _openImageViewer(allMessages, urls.first),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: urls.first,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 220,
              height: 220,
              color: AppColors.obsidianBase,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: 220,
              height: 220,
              color: AppColors.obsidianBase,
              child: const Icon(Icons.error),
            ),
          ),
        ),
      );
    }

    final gridHeight = visibleCount <= 2 ? 110.0 : 220.0;

    return SizedBox(
      width: 220,
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: visibleCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final url = urls[index];
          final overflowCount = urls.length - visibleCount;

          return GestureDetector(
            onTap: isSelectionMode
                ? null
                : () => _openImageViewer(allMessages, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => Container(
                      color: AppColors.obsidianBase,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, failedUrl, error) => Container(
                      color: AppColors.obsidianBase,
                      child: const Icon(Icons.error),
                    ),
                  ),
                  if (index == visibleCount - 1 && overflowCount > 0)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Text(
                        '+$overflowCount',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
                      if (_isGroupedImageContinuation(messages, index)) {
                        return const SizedBox.shrink();
                      }
                      final isMe = msg.senderId == currentUser?.uid;
                      return _buildMessageBubble(
                        msg,
                        isMe,
                        currentUser,
                        messages,
                        index,
                      );
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
    List<MessageModel> allMessages,
    int messageIndex,
  ) {
    final isSelected = _selectedMessageIds.contains(message.id);
    final isSelectionMode = _selectedMessageIds.isNotEmpty;
    final imageGroup = _collectImageGroup(allMessages, messageIndex);

    return SwipeToReplyWrapper(
      onReply: () {
        if (!message.isDeleted) {
          setState(() {
            _replyingTo = message;
            _replyingPreviewText = _replyPreviewTextForMessage(
              message,
              imageGroup.length,
            );
          });
        }
      },
      child: GestureDetector(
        onLongPress: () => _toggleMessageSelection(message.id),
        onDoubleTapDown: (details) {
          _lastReactionTapPosition = details.globalPosition;
        },
        onDoubleTap: () {
          if (!isSelectionMode && !message.isDeleted) {
            _showReactionPicker(message, anchor: _lastReactionTapPosition);
          }
        },
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: message.type == 'image'
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                          decoration: BoxDecoration(
                            color: message.isDeleted
                                ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white10
                                      : Colors.black12)
                                : (isMe
                                      ? (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(46)
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(31))
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
                                    Theme.of(context).brightness ==
                                        Brightness.light
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
                                        margin: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(38),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                                    ? Colors.white.withAlpha(
                                                        204,
                                                      )
                                                    : Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (message.type == 'image' &&
                                        message.imageUrl != null)
                                      _buildGroupedImageContent(
                                        group: imageGroup,
                                        allMessages: allMessages,
                                        isSelectionMode: isSelectionMode,
                                      )
                                    else if (message.type == 'audio' &&
                                        message.audioUrl != null)
                                      AudioPlayerWidget(
                                        audioUrl: message.audioUrl!,
                                        isMe: isMe,
                                        initialDurationMs:
                                            message.audioDurationMs,
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 2.0,
                                        ),
                                        child: Text(
                                          message.text ?? '',
                                          style: GoogleFonts.outfit(
                                            color: isMe
                                                ? (Theme.of(
                                                            context,
                                                          ).brightness ==
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
                                    _buildMetadata(
                                      message,
                                      isMe,
                                      onImage: message.type == 'image',
                                    ),
                                  ],
                                ),
                        ),
                        if (message.reactions.isNotEmpty)
                          PositionedDirectional(
                            bottom: -11,
                            start: isMe ? null : 10,
                            end: isMe ? 10 : null,
                            child: Transform.translate(
                              offset: Offset(isMe ? 1.5 : -1.5, 0),
                              child: _buildReactionBadge(
                                message,
                                currentUser?.uid,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (message.reactions.isNotEmpty) const SizedBox(height: 10),
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

  List<MapEntry<String, List<String>>> _orderedReactions(
    Map<String, List<String>> reactions,
  ) {
    final entries = reactions.entries.toList();
    entries.sort((a, b) {
      final aIndex = _reactionEmojis.indexOf(a.key);
      final bIndex = _reactionEmojis.indexOf(b.key);
      if (aIndex == -1 && bIndex == -1) {
        return a.key.compareTo(b.key);
      }
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    return entries;
  }

  Widget _buildReactionBadge(MessageModel message, String? currentUid) {
    final reactions = _orderedReactions(message.reactions);
    final total = reactions.fold<int>(
      0,
      (sum, entry) => sum + entry.value.length,
    );
    final didReact = currentUid != null
        ? _didUserReact(message, currentUid)
        : false;
    final visibleEmojis = reactions.take(2).map((entry) => entry.key).toList();

    return GestureDetector(
      onTapDown: (details) =>
          _showReactionPicker(message, anchor: details.globalPosition),
      child: Container(
        constraints: const BoxConstraints(minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: didReact ? const Color(0xB3262F35) : const Color(0xAF1F272C),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: didReact ? Colors.white38 : Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ...visibleEmojis.asMap().entries.expand((entry) {
              final widgets = <Widget>[
                Text(
                  entry.value,
                  style: const TextStyle(fontSize: 13, height: 1.0),
                ),
              ];
              if (entry.key != visibleEmojis.length - 1) {
                widgets.add(const SizedBox(width: 2));
              }
              return widgets;
            }),
            if (visibleEmojis.isNotEmpty) const SizedBox(width: 3),
            Text(
              '$total',
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(214),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isOtherUserTyping, UserModel? currentUser) {
    final hasText = _messageController.text.trim().isNotEmpty;

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
          if (_isRecordingVoice)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.mic_rounded,
                    size: 16,
                    color: AppColors.electricRose,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recording voice note... tap stop to send',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _cancelVoiceRecording,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      'Discard',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
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
                                _replyingPreviewText ??
                                    _replyingTo!.text ??
                                    (_replyingTo!.type == 'audio'
                                        ? _voiceReplyPreview()
                                        : '📷 Image'),
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
                          onPressed: () => setState(() {
                            _replyingTo = null;
                            _replyingPreviewText = null;
                          }),
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
                        icon: _isUploadingImages
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              )
                            : Icon(
                                Icons.add_rounded,
                                size: 24,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        onPressed:
                            (_isUploadingImages ||
                                _isUploadingVoice ||
                                _isRecordingVoice)
                            ? null
                            : _sendImages,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        readOnly: _isRecordingVoice,
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
                        icon: _isUploadingVoice
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                hasText
                                    ? Icons.arrow_upward_rounded
                                    : (_isRecordingVoice
                                          ? Icons.stop_rounded
                                          : Icons.mic_rounded),
                                color: Colors.white,
                                size: 20,
                              ),
                        onPressed: _isUploadingVoice
                            ? null
                            : () {
                                if (_isRecordingVoice) {
                                  _stopAndSendVoiceRecording();
                                  return;
                                }
                                if (hasText) {
                                  _sendMessage();
                                  return;
                                }
                                _startVoiceRecording();
                              },
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

class _ChatImageGalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ChatImageGalleryScreen({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ChatImageGalleryScreen> createState() =>
      _ChatImageGalleryScreenState();
}

class _ChatImageGalleryScreenState extends State<_ChatImageGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white70,
                  size: 42,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
