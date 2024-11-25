import 'package:flutter/material.dart';
import '../settings/settings_controller.dart';
import '../widgets/toolbar.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  State<Dashboard> createState() => _LoggedInPageState();
}

class _LoggedInPageState extends State<Dashboard> {
  String? userEmail;
  bool isLoading = true;
  List<Device> devices = [
    Device(name: 'Device 1', status: 'Online'),
    Device(name: 'Device 2', status: 'Offline'),
    Device(name: 'Device 3', status: 'Online'),
    Device(name: 'Device 4', status: 'Offline'),
    Device(name: 'Device 5', status: 'Online'),
  ];

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchUserEmail();
  }

  Future<void> _fetchUserEmail() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final emailAttribute = attributes.firstWhere(
        (attr) => attr.userAttributeKey.key == 'email',
        orElse: () => const AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.email,
          value: 'Unknown',
        ),
      );
      _updateState(() {
        userEmail = emailAttribute.value;
      });
    } catch (e) {
      debugPrint('Error fetching user email: $e');
      _updateState(() {
        userEmail = 'Unknown';
      });
    } finally {
      _updateState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );

      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _updateState(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _scrollController.jumpTo(
      _scrollController.offset - details.delta.dx,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = [ // dummy messages
      Message(content: 'Low battery on Device 1', type: MessageType.warning),
      Message(content: 'Temperature too high on Device 2', type: MessageType.alert),
      Message(content: 'Device 3 disconnected', type: MessageType.alert),
      Message(content: 'Firmware update available for Device 1', type: MessageType.warning),
    ];

    return Scaffold(
      appBar: Toolbar(
        username: userEmail ?? 'Loading...',
        siteName: 'D-Monitor',
        settingsController: widget.settingsController,
        onSignOut: _signOut,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Foreground content
          Column(
            children: [
              const SizedBox(height: 16),

              // Hold-and-Drag Horizontal Scrollable Device Cards
              GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                child: SizedBox(
                  height: 150,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(), // Disable native scrolling
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DeviceCard(device: devices[index]),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Message Board
              Expanded(
                child: MessageBoard(messages: messages),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Device {
  final String name;
  final String status;

  Device({required this.name, required this.status});
}

class DeviceCard extends StatelessWidget {
  final Device device;
  final double opacity;

  const DeviceCard({
    super.key, 
    required this.device,
    this.opacity = 0.95,
    });

  @override
  Widget build(BuildContext context) {
    final isOnline = device.status.toLowerCase() == 'online';
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: opacity,
      child: Card(
        color: colorScheme.surfaceDim,
        elevation: 4,
        child: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  device.status,
                  style: TextStyle(
                    fontSize: 14,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

}

enum MessageType { warning, alert }

class Message {
  final String content;
  final MessageType type;

  Message({required this.content, required this.type});
}

class MessageBoard extends StatelessWidget {
  
  final List<Message> messages;
  final double opacity;

  const MessageBoard({
    super.key,
    required this.messages,
    this.opacity = 0.95, // Default opacity
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: opacity,
      child: Card(
        color: colorScheme.surfaceDim,
        margin: const EdgeInsets.all(16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Message Board',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final color = message.type == MessageType.warning
                        ? Colors.orange
                        : Colors.red;
                    final icon = message.type == MessageType.warning
                        ? Icons.warning
                        : Icons.error;

                    return ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(
                        message.content,
                        style: TextStyle(color: color),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}