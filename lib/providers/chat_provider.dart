import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'auth_provider.dart';

final userChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.watch(firestoreServiceProvider).streamUserChats(user.id);
  }
  return Stream.value([]);
});

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.watch(firestoreServiceProvider).streamMessages(chatId, user.id);
  }
  return Stream.value([]);
});

final chatProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  return ref.watch(firestoreServiceProvider).streamChat(chatId);
});

// ─── Paginated messages ────────────────────────────────────────────────────

class PaginatedMessagesState {
  final List<MessageModel> messages;
  final bool isLoadingMore;
  final bool hasMore;

  const PaginatedMessagesState({
    this.messages = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  PaginatedMessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoadingMore,
    bool? hasMore,
  }) => PaginatedMessagesState(
    messages: messages ?? this.messages,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
  );
}

class PaginatedMessagesNotifier extends Notifier<PaginatedMessagesState> {
  String? _chatId;

  @override
  PaginatedMessagesState build() => const PaginatedMessagesState();

  // Must be called once immediately after the provider is first read.
  void init(String chatId) {
    if (_chatId == chatId) return; // already initialised
    _chatId = chatId;
    // Fire immediately so the current stream value populates state at once.
    ref.listen<AsyncValue<List<MessageModel>>>(
      chatMessagesProvider(chatId),
      (_, next) => _merge(chatId, next.value ?? []),
      fireImmediately: true,
    );
  }

  void _merge(String chatId, List<MessageModel> fresh) {
    final existing = state.messages;
    if (existing.isEmpty) {
      state = state.copyWith(messages: fresh);
      return;
    }
    final freshIds = {for (final m in fresh) m.id};
    final cutoff = fresh.isNotEmpty ? fresh.last.timestamp : DateTime.now();
    final older = existing
        .where((m) => m.timestamp.isBefore(cutoff) && !freshIds.contains(m.id))
        .toList();
    final merged = [...fresh, ...older]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = state.copyWith(messages: merged);
  }

  Future<void> loadMore(String chatId) async {
    if (state.isLoadingMore || !state.hasMore || state.messages.isEmpty) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final oldest = state.messages.last.timestamp;
      final page = await ref
          .read(firestoreServiceProvider)
          .fetchOlderMessages(chatId, user.id, oldest);

      if (page.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }
      final ids = {for (final m in state.messages) m.id};
      final merged = [
        ...state.messages,
        ...page.where((m) => !ids.contains(m.id)),
      ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(
        messages: merged,
        isLoadingMore: false,
        hasMore: page.length == 50,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

// One provider per chatId, lazily created and cached.
final _paginatedCache =
    <
      String,
      NotifierProvider<PaginatedMessagesNotifier, PaginatedMessagesState>
    >{};

NotifierProvider<PaginatedMessagesNotifier, PaginatedMessagesState>
paginatedMessagesProvider(String chatId) {
  return _paginatedCache.putIfAbsent(
    chatId,
    () => NotifierProvider<PaginatedMessagesNotifier, PaginatedMessagesState>(
      () => PaginatedMessagesNotifier(),
    ),
  );
}
