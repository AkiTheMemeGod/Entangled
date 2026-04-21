import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/routes.dart';
import 'models/notification_model.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

import 'theme/theme_variants.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class EntangledApp extends ConsumerWidget {
  const EntangledApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final palette = ThemePalette.getPalette(settings.variant);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Entangled',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(palette),
      darkTheme: AppTheme.getDarkTheme(palette),
      themeMode: settings.mode,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        return _InAppNotificationFlyout(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _InAppNotificationFlyout extends ConsumerStatefulWidget {
  final Widget child;

  const _InAppNotificationFlyout({required this.child});

  @override
  ConsumerState<_InAppNotificationFlyout> createState() =>
      _InAppNotificationFlyoutState();
}

class _InAppNotificationFlyoutState
    extends ConsumerState<_InAppNotificationFlyout> {
  final Set<String> _shownIds = <String>{};
  ProviderSubscription<AsyncValue<List<NotificationModel>>>?
  _notificationsSubscription;
  OverlayEntry? _activeFlyout;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _notificationsSubscription = ref
        .listenManual<AsyncValue<List<NotificationModel>>>(
          notificationsProvider,
          (previous, next) {
            final current = next.value ?? const <NotificationModel>[];
            if (current.isEmpty) return;

            final previousIds = {
              for (final item
                  in (previous?.value ?? const <NotificationModel>[]))
                item.id,
            };

            final latestUnread = current.firstWhere(
              (n) => !n.isRead,
              orElse: () => NotificationModel(
                id: '',
                recipientId: '',
                senderId: '',
                chatId: '',
                type: '',
                title: '',
                body: '',
                isRead: true,
                createdAt: DateTime.now(),
              ),
            );

            final isNew =
                latestUnread.id.isNotEmpty &&
                !previousIds.contains(latestUnread.id) &&
                !_shownIds.contains(latestUnread.id);

            if (!isNew || !mounted) return;

            _shownIds.add(latestUnread.id);
            _showFlyout(latestUnread);
          },
          fireImmediately: false,
        );
  }

  void _showFlyout(NotificationModel item) {
    _activeFlyout?.remove();
    _activeFlyout = null;
    _dismissTimer?.cancel();

    final navigator = appNavigatorKey.currentState;
    final navigatorContext = appNavigatorKey.currentContext;
    final overlay = navigator?.overlay;
    if (overlay == null || navigatorContext == null) {
      return;
    }

    _activeFlyout = OverlayEntry(
      builder: (overlayContext) {
        final topInset = MediaQuery.of(overlayContext).padding.top + 10;
        return Positioned(
          top: topInset,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: -20, end: 0),
              duration: const Duration(milliseconds: 220),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () {
                  _activeFlyout?.remove();
                  _activeFlyout = null;
                  navigator?.pushNamed(
                    AppRoutes.chat,
                    arguments: {
                      'chatId': item.chatId,
                      'otherUserId': item.senderId,
                      'otherUserName': item.title,
                      'otherUserPhoto': null,
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(navigatorContext).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(
                        navigatorContext,
                      ).colorScheme.primary.withAlpha(70),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        color: Theme.of(navigatorContext).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Theme.of(
                                  navigatorContext,
                                ).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Theme.of(
                                  navigatorContext,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_activeFlyout!);
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _activeFlyout?.remove();
      _activeFlyout = null;
    });
  }

  @override
  void dispose() {
    _notificationsSubscription?.close();
    _dismissTimer?.cancel();
    _activeFlyout?.remove();
    _activeFlyout = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
