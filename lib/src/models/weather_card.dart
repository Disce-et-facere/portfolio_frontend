import 'package:flutter/material.dart';

class WeatherDeviceCard extends StatelessWidget {
  final String temperature;
  final String windSpeed;
  final String description;
  final VoidCallback onTap;

  const WeatherDeviceCard({
    super.key,
    required this.temperature,
    required this.windSpeed,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                'Stockholm Weather',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
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
