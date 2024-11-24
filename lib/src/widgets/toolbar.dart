import 'package:flutter/material.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_view.dart';
import 'user_screen.dart';
import 'add_device_screen.dart';

class Toolbar extends StatelessWidget implements PreferredSizeWidget {
  const Toolbar({
    super.key,
    required this.username,
    required this.siteName,
    required this.settingsController,
    required this.onSignOut,
  });

  final String username;
  final String siteName;
  final SettingsController settingsController;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AppBar(
      backgroundColor: colorScheme.surfaceDim,
      foregroundColor: colorScheme.onSurface,
      elevation: 2,
      title: Row(
        children: [
          // Logo and Site Name
          Image.asset(
            'assets/images/logo.png',
            height: 40,
          ),
          const SizedBox(width: 8),
          Text(
            siteName,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        // User Button
        IconButton(
          icon: Icon(Icons.person, color: colorScheme.onSurface),
          tooltip: 'User',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserScreen(username: username),
              ),
            );
          },
        ),

        // Add Device Button
        IconButton(
          icon: Icon(Icons.devices, color: colorScheme.onSurface),
          tooltip: 'Add Device',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DeviceFormScreen(),
              ),
            );
          },
        ),

        // Logout Button
        IconButton(
          icon: Icon(Icons.logout, color: colorScheme.onSurface),
          tooltip: 'Sign Out',
          onPressed: () => _confirmSignOut(context),
        ),

        // Settings Button
        IconButton(
          icon: Icon(Icons.settings, color: colorScheme.onSurface),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SettingsView(controller: settingsController),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Show a confirmation dialog before signing out
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Sign Out',
            style: theme.textTheme.titleMedium,
          ),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onSignOut(); // Perform sign-out action
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
