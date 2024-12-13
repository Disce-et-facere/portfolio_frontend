import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeatherGraphScreen extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const WeatherGraphScreen({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final spots = weeklyData
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              double.parse(entry.value['temperature']),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Stockholm Weather - Last Week')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Week\'s Weather',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final dayIndex = value.toInt();
                          if (dayIndex < 0 || dayIndex >= weeklyData.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.parse(weeklyData[dayIndex]['date']);
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
