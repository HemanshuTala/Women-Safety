import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_user/src/providers/auth_provider.dart' show AuthProvider;
import 'src/providers/socket_provider.dart';
import 'src/providers/location_provider.dart';

import 'src/routes.dart';
import 'src/services/api_service.dart';
import 'src/theme.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/user_home.dart';
import 'src/screens/parent_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WomenSafetyApp());
}

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({Key? key}) : super(key: key);

  Widget _getInitialScreen(AuthProvider auth) {
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }
    
    final userRole = auth.user?['role']?.toString();
    if (userRole == 'parent') {
      return const ParentHome();
    } else {
      return const UserHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiService(baseUrl: 'https://women-safety-mcsp.onrender.com'); // Change to your backend URL

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ChangeNotifierProvider(create: (_) => SocketProvider(api)),
        ChangeNotifierProvider(create: (_) => LocationProvider(api)),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return MaterialApp(
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }


          return MaterialApp(
            title: 'Women Safety',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            home: _getInitialScreen(auth),
            onGenerateRoute: (settings) {
              try {
                return AppRoutes.generateRoute(settings);
              } catch (e) {
                debugPrint('Route generation error: $e');
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Navigation Error'),
                          SizedBox(height: 8),
                          Text('$e'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                            child: Text('Go to Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
