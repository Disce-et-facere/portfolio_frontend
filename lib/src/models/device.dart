// models/device.dart
class Device {
  String name;
  String status; // Removed `final`
  int timestamp;
  Map<String, dynamic> data; // Ensure this is a Map<String, dynamic>

  Device({
    required this.name,
    required this.status,
    required this.timestamp,
    required this.data,
  });
}