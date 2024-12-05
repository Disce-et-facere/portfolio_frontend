// models/device.dart
class Device {
  final String name;
  final String status;
  final int timestamp;
  final Map<String, dynamic> data;

  Device({
    required this.name,
    required this.status,
    required this.timestamp,
    required this.data,
  });
}