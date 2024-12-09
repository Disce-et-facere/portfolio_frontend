import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart'; // For ModelQueries
import '../settings/settings_controller.dart';
import 'dart:convert';
import '../widgets/toolbar.dart';
import '../widgets/device_detail_screen.dart';
import '../../models/telemetry.dart'; // Generated telemetry model
import '../../models/ModelProvider.dart'; // Required for ModelQueries

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? userEmail;
  String ownerId = '';
  bool isLoading = true;
  List<telemetry> devices = [];
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
  try {
    final request = ModelQueries.list(
      telemetry.classType,
      where: telemetry.OWNERID.eq(ownerId),
    );

    final response = await Amplify.API.query(request: request).response;

    if (response.data != null) {
      // Group by device_id
      final groupedDevices = <String, telemetry>{};

      for (var device in response.data!.items.whereType<telemetry>()) {
        groupedDevices[device.device_id] = device;
      }

      setState(() {
        devices = groupedDevices.values.toList();
      });

      // Fetch shadow data for each device
      for (final device in devices) {
        await _fetchShadow(device.device_id);
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
          if (device.device_id == deviceId) {
            return device.copyWith(
              deviceData: jsonEncode({
                ...(jsonDecode(device.deviceData) as Map<String, dynamic>),
                'status': shadowData['state']['reported']['status'] ?? 'Unknown',
              }),
            );
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
                    ? MessageBoard(messages: messages, devices: devices)
                    : MessageBoard(messages: messages, devices: devices),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final telemetry device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final deviceDataMap = jsonDecode(device.deviceData) as Map<String, dynamic>;
    final status = deviceDataMap.containsKey('status') ? deviceDataMap['status'] : 'Unknown';

    final formattedTimestamp = DateTime.fromMillisecondsSinceEpoch(
      (device.timestamp.toSeconds() * 1000).toInt(),
    ).toString();

    return Card(
      color: colorScheme.surface,
      elevation: 4,
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    status == 'Online' ? Icons.check_circle : Icons.error,
                    color: status == 'Online' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Device ID: ${device.device_id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Status: $status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: status == 'Online' ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: $formattedTimestamp',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              // Display other device data
              ...deviceDataMap.entries.map((entry) {
                if (entry.key == 'status') return Container(); // Skip status
                return Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 12),
                );
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
  final List<telemetry> devices; // Pass the devices list as a parameter

  const MessageBoard({
    super.key,
    required this.messages,
    required this.devices,
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
              child: devices.isEmpty
                  ? ListView(
                      children: messages.map((message) {
                        final color = message.type == MessageType.warning ? Colors.orange : Colors.red;
                        final icon = message.type == MessageType.warning ? Icons.warning : Icons.error;
                        return ListTile(
                          leading: Icon(icon, color: color),
                          title: Text(
                            message.content,
                            style: TextStyle(color: color),
                          ),
                        );
                      }).toList(),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) => DeviceCard(device: devices[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
