import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TemperaturePage extends StatelessWidget {
  const TemperaturePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Données statiques pour les températures
    final Map<String, double> temperatures = {
      'zone1': 22.5,
      'zone2': 23.0,
      'zone3': 21.8,
    };

    // Données statiques pour les graphiques
    final List<FlSpot> tgbtSpots = [
      FlSpot(0, 22.0),
      FlSpot(1, 22.2),
      FlSpot(2, 22.5),
      FlSpot(3, 22.7),
      FlSpot(4, 23.0),
      FlSpot(5, 23.2),
      FlSpot(6, 23.5),
      FlSpot(7, 23.3),
      FlSpot(8, 23.0),
    ];

    final List<FlSpot> compresseurSpots = [
      FlSpot(0, 22.5),
      FlSpot(1, 22.7),
      FlSpot(2, 23.0),
      FlSpot(3, 23.2),
      FlSpot(4, 23.5),
      FlSpot(5, 23.3),
      FlSpot(6, 23.0),
      FlSpot(7, 22.8),
      FlSpot(8, 22.5),
    ];

    final List<FlSpot> climatisationSpots = [
      FlSpot(0, 22.0),
      FlSpot(1, 21.8),
      FlSpot(2, 21.5),
      FlSpot(3, 21.3),
      FlSpot(4, 21.0),
      FlSpot(5, 21.2),
      FlSpot(6, 21.5),
      FlSpot(7, 21.7),
      FlSpot(8, 22.0),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/brain71.png', height: 36),
            const SizedBox(width: 10),
            const Text(
              'EnergyTrack',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF0D47A1),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFF1976D2)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTemperatureCard('Zone 1', '${temperatures['zone1']?.toStringAsFixed(2)}°C', Colors.red),
            const SizedBox(height: 12),
            _buildTemperatureCard('Zone 2', '${temperatures['zone2']?.toStringAsFixed(2)}°C', Colors.red),
            const SizedBox(height: 12),
            _buildTemperatureCard('Zone 3', '${temperatures['zone3']?.toStringAsFixed(2)}°C', Colors.red),
            const SizedBox(height: 24),
            _buildLineChart(tgbtSpots, compresseurSpots, climatisationSpots, temperatures),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureCard(String title, String temp, Color indicatorColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: indicatorColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.thermostat, size: 30),
                const SizedBox(width: 8),
                Text(
                  temp,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: indicatorColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.power_settings_new, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                    label: const Text('Manuel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.ac_unit),
                    label: const Text('Auto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
      List<FlSpot> tgbtSpots,
      List<FlSpot> compresseurSpots,
      List<FlSpot> climatisationSpots,
      Map<String, double> temperatures,
      ) {
    const double minX = 0;
    const double maxX = 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Variation des températures',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: 15,
                maxY: 30,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value < minX || value > maxX) return const SizedBox.shrink();
                        return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}°C', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                    width: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: tgbtSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: compresseurSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: climatisationSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("Zone 1 : ${temperatures['zone1']?.toStringAsFixed(2)} °C"),
            Text("Zone 2 : ${temperatures['zone2']?.toStringAsFixed(2)} °C"),
            Text("Zone 3 : ${temperatures['zone3']?.toStringAsFixed(2)} °C"),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.red, 'TGBT'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.green, 'Compresseur'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.blue, 'Climatisation'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
