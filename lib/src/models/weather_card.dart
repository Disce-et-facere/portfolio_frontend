import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherDeviceCard extends StatelessWidget {
  final String temperature;
  final String windSpeed;
  final String description;
  final DateTime dateTime; // Add DateTime as a parameter
  final VoidCallback onTap;

  const WeatherDeviceCard({
    super.key,
    required this.temperature,
    required this.windSpeed,
    required this.description,
    required this.dateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format date and time
    final formattedDate = DateFormat('EEEE, MMM d').format(dateTime); // Ex: Friday, Dec 15
    final formattedTime = DateFormat('h:mm a').format(dateTime); // Ex: 2:30 PM

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Weather Forecast - Stockholm',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('Date: $formattedDate'),
              Text('Time: $formattedTime'),
              const SizedBox(height: 8),
              Text('Temperature: $temperature°C'),
              Text('Wind Speed: $windSpeed m/s'),
              Text('Description: $description'),
            ],
          ),
        ),
      ),
    );
  }
}
