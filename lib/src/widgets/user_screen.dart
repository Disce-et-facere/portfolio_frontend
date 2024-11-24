import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class UserScreen extends StatefulWidget {
  final String username;

  const UserScreen({super.key, required this.username});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String _ownerID = '';
  final TextEditingController _ownerIDController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOwnerID();
  }

  Future<void> _loadOwnerID() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final ownerIDAttribute = attributes.firstWhere(
        (attr) => attr.userAttributeKey == const CognitoUserAttributeKey.custom('ownerID'),
        orElse: () => const AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('ownerID'),
          value: '',
        ),
      );
      setState(() {
        _ownerID = ownerIDAttribute.value;
        _ownerIDController.text = _ownerID;
      });
    } catch (e) {
      debugPrint('Error loading OwnerID: $e');
    }
  }

Future<void> _saveOwnerID() async {
  final newOwnerID = _ownerIDController.text.trim();
  if (newOwnerID.isNotEmpty) {
    try {
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: const CognitoUserAttributeKey.custom('ownerID'),
        value: newOwnerID,
      );
      debugPrint('OwnerID updated to: $newOwnerID');

      if (!mounted) return; // Ensure the widget is still mounted

      setState(() {
        _ownerID = newOwnerID;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner ID updated successfully')),
      );
    } catch (e) {
      debugPrint('Error updating OwnerID: $e');

      if (!mounted) return; // Ensure the widget is still mounted

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating Owner ID: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${widget.username}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Owner ID: $_ownerID',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ownerIDController,
              decoration: InputDecoration(
                labelText: 'Edit Owner ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _saveOwnerID,
                child: const Text('Update Owner ID'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ownerIDController.dispose();
    super.dispose();
  }
}
