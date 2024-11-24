import 'package:flutter/material.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'loggedin/loggedin_page.dart';
import 'settings/settings_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController, // Listen for changes in settingsController
      builder: (BuildContext context, Widget? child) {
        return Authenticator(
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: settingsController.themeMode, // Use dynamic themeMode
            builder: Authenticator.builder(),
            home: AuthWrapper(settingsController: settingsController),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isAuthenticated = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      setState(() {
        isAuthenticated = session.isSignedIn;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching auth session: $e');
      setState(() {
        isAuthenticated = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Show a loading spinner while checking authentication
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (isAuthenticated) {
      // User is authenticated, show the logged-in page
      return LoggedInPage(settingsController: widget.settingsController);
    }

    // User is not authenticated, show the Authenticator login UI
    return Authenticator(
      child: const SizedBox.shrink(),
    );
  }
}
