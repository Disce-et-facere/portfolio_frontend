import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart'; // For ModelQueries
import '../settings/settings_controller.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
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

  const queryDocument = '''
    query FetchDeviceShadow(\$deviceId: String!) {
      fetchDeviceShadow(deviceId: \$deviceId) {
        deviceId
        status
        deviceData
      }
    }
  ''';

  try {
    final response = await Amplify.API.query<String>(
      request: GraphQLRequest<String>(
        document: queryDocument,
        variables: {'deviceId': deviceId},
      ),
    ).response;

    if (response.data != null) {
      final shadowData = jsonDecode(response.data!) as Map<String, dynamic>;

      debugPrint('Shadow Data for $deviceId: $shadowData');

      final fetchedShadow = shadowData['fetchDeviceShadow'];
      if (fetchedShadow == null) {
        debugPrint('No shadow data returned for device: $deviceId');
        return;
      }

      final status = fetchedShadow['status'] ?? 'Unknown';
      final deviceData = fetchedShadow['deviceData'] ?? {};

      setState(() {
        devices = devices.map((device) {
          if (device.device_id == deviceId) {
            return device.copyWith(
              deviceData: jsonEncode({
                ...(jsonDecode(device.deviceData) as Map<String, dynamic>),
                'status': status,
                ...deviceData,
              }),
            );
          }
          return device;
        }).toList();
      });
    } else {
      debugPrint('No data received from shadow query for device: $deviceId');
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
  final telemetry device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final deviceDataMap = jsonDecode(device.deviceData) as Map<String, dynamic>;
    final status = deviceDataMap['status'] ?? 'Unknown';

    final formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(
        device.timestamp.toSeconds(),
      ).toLocal(),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    status == 'Online' ? Icons.check_circle : Icons.error,
                    color: status == 'Online' ? Colors.green : Colors.red,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Device ID: ${device.device_id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
            const Divider(),
            // Display other device data
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: deviceDataMap.entries.map((entry) {
                if (entry.key == 'status') return Container(); // Skip status
                if (entry.key.endsWith('-unit')) return Container(); // Skip unit keys directly

                final unitKey = '${entry.key}-unit';
                final unit = deviceDataMap.containsKey(unitKey) ? deviceDataMap[unitKey] : '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '${entry.key}: ${entry.value} $unit',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
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

enum MessageType { warning, alert, info }

class MessageBoard extends StatelessWidget {
  final List<Message> messages;

  const MessageBoard({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Flexible(
      flex: 1, // Adjust flex value as needed
      child: Card(
        color: colorScheme.surface,
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
                child: messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages to display.',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final color = _getMessageColor(message.type);
                          final icon = _getMessageIcon(message.type);

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

  Color _getMessageColor(MessageType type) {
    switch (type) {
      case MessageType.warning:
        return Colors.orange;
      case MessageType.alert:
        return Colors.red;
      case MessageType.info:
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.warning:
        return Icons.warning;
      case MessageType.alert:
        return Icons.error;
      case MessageType.info:
        return Icons.info;
      default:
        return Icons.message;
    }
  }
}


