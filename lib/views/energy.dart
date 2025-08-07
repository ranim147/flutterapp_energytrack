import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

class EnergyPage extends StatefulWidget {
  const EnergyPage({Key? key}) : super(key: key);

  @override
  State<EnergyPage> createState() => _EnergyPageState();
}

class EnergyData {
  final int timestamp;
  final double value;

  EnergyData({required this.timestamp, required this.value});
}

class _EnergyPageState extends State<EnergyPage> {
  bool _isLoading = false;
  String _selectedType = 'tgbt';
  String? _currentMonth;
  late List<EnergyData> _energyDataAll;
  late Future<List<EnergyData>> _energyDataFuture = Future.value([]);
  double monthlyConsumption = 0.0;

  Future<List<String>> fetchAvailableDates(String type) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/energy/$type/dates'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      } else {
        print('Erreur dates: ${response.statusCode}');
        throw Exception('Failed to fetch dates');
      }
    } catch (e) {
      print('Erreur fetchDates: $e');
      throw e;
    }
  }

  DateTime parseDate(String dateStr) {
    try {
      final day = int.parse(dateStr.substring(0, 2));
      final month = int.parse(dateStr.substring(2, 4));
      final year = int.parse(dateStr.substring(4, 8));
      return DateTime(year, month, day);
    } catch (e) {
      print('Erreur parsing date: $e');
      return DateTime.now();
    }
  }

  String getLastCompleteMonth(List<String> dates) {
    dates.sort();
    final lastDate = parseDate(dates.last);
    return '${lastDate.year}-${lastDate.month.toString().padLeft(2, '0')}';
  }

  Future<List<dynamic>> fetchEnergyData(String type, String date) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/energy/$type/$date'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is List) return responseData;
        if (responseData is Map && responseData['values'] is List) {
          return responseData['values'];
        }
      }
      return [];
    } catch (e) {
      print('Erreur fetchEnergyData: $e');
      return [];
    }
  }

  Future<List<EnergyData>> fetchMonthData(String type, String month) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/energy/$type/dates'));

      if (response.statusCode == 200) {
        final dates = List<String>.from(json.decode(response.body));
        List<String> filteredDates = dates.where((date) {
          try {
            final parsedDate = parseDate(date);
            return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}' == month;
          } catch (_) {
            return false;
          }
        }).toList();

        if (filteredDates.isEmpty) return [];

        double totalKWh = 0;
        List<EnergyData> allData = [];

        for (String date in filteredDates) {
          final dayData = await fetchEnergyData(type, date);

          for (var entry in dayData) {
            try {
              final dynamic valueData = entry['value'];
              final double value = valueData is String
                  ? double.tryParse(valueData) ?? 0.0
                  : (valueData as num).toDouble();

              allData.add(EnergyData(
                timestamp: entry['ts'] as int,
                value: value,
              ));
              totalKWh += value / 3600000;
            } catch (e) {
              print('Erreur processing entry: $e');
            }
          }
        }

        setState(() => monthlyConsumption = totalKWh);
        return allData;
      }
      return [];
    } catch (e) {
      print('Erreur fetchMonthData: $e');
      return [];
    }
  }

  void _loadInitialData() async {
    setState(() => _isLoading = true); // Active le loading

    try {
      final dates = await fetchAvailableDates(_selectedType);
      final lastMonth = getLastCompleteMonth(dates);
      final monthData = await fetchMonthData(_selectedType, lastMonth);

      setState(() {
        _currentMonth = lastMonth;
        _energyDataAll = monthData;
        _energyDataFuture = Future.value(monthData);
      });
    } catch (e) {
      print("Erreur chargement données : $e");
    } finally {
      setState(() => _isLoading = false); // Désactive le loading
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  List<double> _getLast7DaysConsumption(List<EnergyData> monthData) {
    if (monthData.isEmpty) return List.filled(7, 0.0);

    monthData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(monthData.last.timestamp);

    List<double> values = List.filled(7, 0.0);
    Map<String, List<EnergyData>> groupedByDay = {};

    for (var entry in monthData) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
      String dayKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      groupedByDay.putIfAbsent(dayKey, () => []).add(entry);
    }

    for (int i = 0; i < 7; i++) {
      final day = lastDate.subtract(Duration(days: 6 - i));
      final dayKey = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
      final entries = groupedByDay[dayKey];

      if (entries != null && entries.length >= 2) {
        values[i] = (entries.last.value - entries.first.value) / 1000;
      }
    }

    return values;
  }

  List<double> _getMonthlyData(List<EnergyData> allData, String currentMonth) {
    if (allData.isEmpty) return List.filled(6, 0.0);

    allData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final year = int.parse(currentMonth.substring(0, 4));
    final month = int.parse(currentMonth.substring(5, 7));

    final monthlyValues = List<double>.filled(6, 0.0);

    for (int i = 0; i < 6; i++) {
      final current = DateTime(year, month - 5 + i);
      final next = DateTime(current.year, current.month + 1);

      final monthData = allData.where((data) {
        final date = DateTime.fromMillisecondsSinceEpoch(data.timestamp);
        return !date.isBefore(current) && date.isBefore(next);
      }).toList();

      if (monthData.length >= 2) {
        monthlyValues[i] = (monthData.last.value - monthData.first.value) / 1000;
      }
    }

    return monthlyValues;
  }

  final Map<String, Color> _typeColors = {
    'tgbt': const Color(0xFFE53935),
    'compresseurs': const Color(0xFF43A047),
    'climatisation': const Color(0xFF1E88E5),
  };
  Color _getTypeColor() {
    return _typeColors[_selectedType] ?? Colors.blue;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final bool isSelected = _selectedType == type;
    final color = _typeColors[type] ?? const Color(0xFF1E88E5);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _loadInitialData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildModernConsumptionCard({
    required String title,
    required String currentValue,
    required String previousValue,
    required String variation,
    required bool isPositive,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currentValue,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              previousValue,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              variation,
              style: TextStyle(
                fontSize: 14,
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard({
    required String title,
    required double maxY,
    required List<double> values,
    required bool isMonth,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: maxY,
                  minY: 0,
                  groupsSpace: isMonth ? 20 : 15,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)} kWh',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              isMonth ? 'M${index + 1}' : 'J-${6 - index}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(maxY / 4, 0.1),
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value >= 1000
                                ? '${(value / 1000).toStringAsFixed(1)}k'
                                : value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: max(maxY / 4, 0.1),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  barGroups: List.generate(values.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index],
                          color: color.withOpacity(0.8),
                          width: isMonth ? 22 : 18,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBarChartCard({
    required String title,
    required double maxY,
    required List<double> values,
    required Color color,
  }) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: maxY,
                  minY: 0,
                  groupsSpace: 12,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)} kWh',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            final isToday = index == 6;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isToday ? color : Colors.grey,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(maxY / 5, 0.1),
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: max(maxY / 5, 0.1),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  barGroups: List.generate(values.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index],
                          color: index == 6
                              ? color
                              : color.withOpacity(0.6),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTypeButton('TGBT', 'tgbt'),
                _buildTypeButton('Compresseur', 'compresseurs'),
                _buildTypeButton('Climatisation', 'climatisation'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EnergyData>>(
              future: _energyDataFuture,
              builder: (context, snapshot) {
                if (_isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_getTypeColor()),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucune donnée disponible'));
                } else {
                  final dailyValues = _getLast7DaysConsumption(snapshot.data!);
                  final monthlyValues = _getMonthlyData(_energyDataAll, _currentMonth!);

                  final maxDaily = dailyValues.isNotEmpty
                      ? max(dailyValues.reduce(max), 0.1) * 1.5
                      : 1.0;
                  final maxMonthly = monthlyValues.isNotEmpty
                      ? max(monthlyValues.reduce(max), 0.1) * 1.5
                      : 1.0;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSectionTitle('Vue mensuelle'),
                          _buildModernConsumptionCard(
                            title: 'Résumé du mois',
                            currentValue: monthlyValues.isNotEmpty
                                ? '${monthlyValues.last.toStringAsFixed(2)} kWh'
                                : '0.00 kWh',
                            previousValue: monthlyValues.length >= 2
                                ? '${monthlyValues[monthlyValues.length - 2].toStringAsFixed(2)} kWh mois précédent'
                                : 'Pas de données',
                            variation: monthlyValues.length >= 2 &&
                                monthlyValues[monthlyValues.length - 2] > 0
                                ? '${(monthlyValues.last - monthlyValues[monthlyValues.length - 2]).toStringAsFixed(2)} kWh (${((monthlyValues.last - monthlyValues[monthlyValues.length - 2]) / monthlyValues[monthlyValues.length - 2] * 100).toStringAsFixed(1)}%)'
                                : 'Nouvelle donnée',
                            isPositive: monthlyValues.length >= 2
                                ? monthlyValues.last > monthlyValues[monthlyValues.length - 2]
                                : true,
                            color: _getTypeColor(),
                          ),
                          const SizedBox(height: 16),
                          _buildBarChartCard(
                            title: 'Historique mensuel',
                            maxY: maxMonthly,
                            values: monthlyValues,
                            isMonth: true,
                            color: _getTypeColor(),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Vue des 7 derniers jours'),
                          _buildModernConsumptionCard(
                            title: "Aujourd'hui",
                            currentValue: dailyValues.isNotEmpty
                                ? '${dailyValues.last.toStringAsFixed(2)} kWh'
                                : '0.00 kWh',
                            previousValue: dailyValues.length >= 2
                                ? '${dailyValues[dailyValues.length - 2].toStringAsFixed(2)} kWh hier'
                                : 'Pas de données',
                            variation: dailyValues.length >= 2 &&
                                dailyValues[dailyValues.length - 2] > 0
                                ? '${(dailyValues.last - dailyValues[dailyValues.length - 2]).toStringAsFixed(2)} kWh (${((dailyValues.last - dailyValues[dailyValues.length - 2]) / dailyValues[dailyValues.length - 2] * 100).toStringAsFixed(1)}%)'
                                : 'Nouvelle donnée',
                            isPositive: dailyValues.length >= 2
                                ? dailyValues.last > dailyValues[dailyValues.length - 2]
                                : true,
                            color: _getTypeColor(),
                          ),
                          const SizedBox(height: 16),
                          _buildDailyBarChartCard(
                            title: 'Consommation des 7 derniers jours',
                            maxY: maxDaily,
                            values: dailyValues,
                            color: _getTypeColor(),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}