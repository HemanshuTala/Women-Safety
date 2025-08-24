import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/user_home.dart';
import 'screens/user_map_screen.dart';
import 'screens/parent_home.dart';
import 'screens/parent_map_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/smart_profile_screen.dart';
import 'screens/connect_child_screen.dart';
import 'screens/sos_history_screen.dart';
import 'screens/settings_screen.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const userHome = '/user_home';
  static const userMap = '/user_map';
  static const parentHome = '/parent_home';
  static const parentMap = '/parent_map';
  static const sos = '/sos';
  static const profile = '/profile';
  static const connectChild = '/connect_child';
  static const sosHistory = '/sos_history';
  static const settings = '/settings';
}

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? Routes.splash;

    switch (routeName) {
      case Routes.splash:
        return _createRoute(const SplashScreen());
      case Routes.login:
        return _createRoute(const LoginScreen());
      case Routes.register:
        return _createRoute(const RegisterScreen());
      case Routes.userHome:
        return _createRoute(const UserHome());
      case Routes.userMap:
        return _createRoute(const UserMapScreen());
      case Routes.parentHome:
        return _createRoute(const ParentHome());
      case Routes.parentMap:
        return _createRoute(const ParentMapScreen());
      case Routes.sos:
        return _createRoute(const SosScreen());
      case Routes.profile:
        return _createRoute(const SmartProfileScreen());
      case Routes.connectChild:
        return _createRoute(const ConnectChildScreen());
      case Routes.sosHistory:
        return _createRoute(const SosHistoryScreen());
      case Routes.settings:
        return _createRoute(const SettingsScreen());
      default:
        return _createRoute(const SplashScreen());
    }
  }

  static Route<dynamic> _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

