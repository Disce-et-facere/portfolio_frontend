import 'package:flutter/material.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_view.dart';

class LoginToolbar extends StatelessWidget implements PreferredSizeWidget {
  const LoginToolbar({
    super.key,
    required this.title,
    required this.settingsController,
  });

  final String title;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
