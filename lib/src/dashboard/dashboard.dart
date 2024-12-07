import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../settings/settings_controller.dart';
import '../widgets/toolbar.dart';
import '../widgets/device_detail_screen.dart';
import '../models/device.dart';

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
  String ownerId = '';
  bool isLoading = true;
  List<Device> devices = [];

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchUserEmail();
    _fetchOwnerId();
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
      setState(() {
        userEmail = emailAttribute.value;
      });
    } catch (e) {
      debugPrint('Error fetching user email: $e');
      setState(() {
        userEmail = 'Unknown';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchOwnerId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final ownerIDAttribute = attributes.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.custom('OwnerID'),
        orElse: () => const AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('OwnerID'),
          value: '',
        ),
      );
      setState(() {
        ownerId = ownerIDAttribute.value;
      });
      if (ownerId.isNotEmpty) {
        await _fetchDevices();
      }
    } catch (e) {
      debugPrint('Error fetching OwnerID: $e');
    }
  }

  Future<void> _fetchDevices() async {
    const query = '''
      query ListDevicesByOwnerID(\$ownerID: ID!) {
        listDevicesByOwnerID(ownerID: \$ownerID) {
          device_id
          timestamp
          deviceData
        }
      }
    ''';

    try {
      final response = await Amplify.API.query<String>(
        request: GraphQLRequest<String>(
          document: query,
          variables: {'ownerID': ownerId},
        ),
      ).response;

      if (response.data != null) {
        final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
        final List<dynamic> devicesData = decoded['listDevicesByOwnerID'] ?? [];

        setState(() {
          devices = devicesData
              .map((device) => Device(
                    name: device['device_id'],
                    status: 'Fetching...', // Placeholder for shadow data
                    timestamp: device['timestamp'],
                    data: Map<String, dynamic>.from(device['deviceData']),
                  ))
              .toList();
        });

        // Fetch shadow data for each device
        for (final device in devices) {
          await _fetchShadow(device.name);
        }
      } else {
        debugPrint('No devices found.');
      }
    } catch (e) {
      debugPrint('Error fetching devices: $e');
    }
  }

  Future<void> _fetchShadow(String deviceId) async {
    debugPrint('Fetching shadow data for device: $deviceId');
    const shadowGetTopic = '\$aws/things/{deviceId}/shadow/get';

    try {
      final shadowResponse = await Amplify.API.query<String>(
        request: GraphQLRequest<String>(
          document: shadowGetTopic.replaceAll('{deviceId}', deviceId),
        ),
      ).response;

      if (shadowResponse.data != null) {
        final shadowData = jsonDecode(shadowResponse.data!) as Map<String, dynamic>;

        setState(() {
          devices = devices.map((device) {
            if (device.name == deviceId) {
              device.status = shadowData['state']['reported']['status'] ?? 'Unknown';
              device.data = Map<String, dynamic>.from(
                  shadowData['state']['reported']['deviceData'] ?? {});
            }
            return device;
          }).toList();
        });
      } else {
        debugPrint('No shadow data for device: $deviceId');
      }
    } catch (e) {
      debugPrint('Error fetching shadow for $deviceId: $e');
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
    final messages = [
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                child: SizedBox(
                  height: 150,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DeviceDetailScreen(device: devices[index]),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DeviceCard(device: devices[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: devices.isEmpty
                    ? MessageBoard(messages: messages)
                    : MessageBoard(messages: messages),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final Device device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final formattedTimestamp = DateTime.fromMillisecondsSinceEpoch(
      device.timestamp * 1000,
    ).toString();

    return Card(
      color: colorScheme.surface,
      elevation: 4,
      child: SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device ID: ${device.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Status: ${device.status}'),
              Text('Last Updated: $formattedTimestamp'),
              ...device.data.entries.map((entry) {
                return Text('${entry.key}: ${entry.value}');
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class Message {
  final String content;
  final MessageType type;

  Message({required this.content, required this.type});
}

enum MessageType { warning, alert }

class MessageBoard extends StatelessWidget {
  final List<Message> messages;

  const MessageBoard({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surface,
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message Board - Dummies',
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
    );
  }
}
