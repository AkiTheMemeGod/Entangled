import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/friend_requests_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/user_search_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String searchUsers = '/searchUsers';
  static const String friendRequests = '/friendRequests';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        login: (context) => const LoginScreen(),
        signup: (context) => const SignupScreen(),
        home: (context) => const HomeScreen(),
        profile: (context) => const ProfileScreen(),
        settings: (context) => const SettingsScreen(),
        searchUsers: (context) => const UserSearchScreen(),
        friendRequests: (context) => const FriendRequestsScreen(),
        // chat screen requires arguments, so we handle it dynamically or via args
      };
      
  static MaterialPageRoute generateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.chat) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: args['chatId'],
          otherUserId: args['otherUserId'],
          otherUserName: args['otherUserName'],
          otherUserPhoto: args['otherUserPhoto'],
        ),
      );
    }
    
    // Fallback
    return MaterialPageRoute(builder: (context) => const SplashScreen());
  }
}
