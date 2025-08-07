import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showHistory = false;
  bool _isLoading = false;

  List<String> _availableDatesTGBT = [];
  List<String> _availableDatesCompresseurs = [];
  List<String> _availableDatesClimatisation = [];

  String? _selectedDateTGBT;
  String? _selectedDateCompresseurs;
  String? _selectedDateClimatisation;

  List<Map<String, dynamic>> _tgbt4h = [];
  List<Map<String, dynamic>> _compress4h = [];
  List<Map<String, dynamic>> _clim4h = [];

  Map<String, dynamic> _energyData = {
    'tgbtDaily': 0.0,
    'compressDaily': 0.0,
    'climDaily': 0.0,
    'tgbtPower': 0.0,
    'compressPower': 0.0,
    'climPower': 0.0,
    'lastUpdate': DateTime.now(),
  };

  Map<String, double> _temperatures = {
    'zone1': 22.0,
    'zone2': 22.0,
    'zone3': 22.0,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchAvailableDates();
    await _fetchEnergyData();
  }

  Future<void> _fetchAvailableDates() async {
    try {
      const baseUrl = 'http://10.0.2.2:3000/api/energy';

      final tgbtDates = await _fetchDates('$baseUrl/tgbt/dates');
      final compDates = await _fetchDates('$baseUrl/compresseurs/dates');
      final climDates = await _fetchDates('$baseUrl/climatisation/dates');

      setState(() {
        _availableDatesTGBT = tgbtDates;
        _availableDatesCompresseurs = compDates;
        _availableDatesClimatisation = climDates;

        _selectedDateTGBT = tgbtDates.isNotEmpty ? tgbtDates.last : null;
        _selectedDateCompresseurs = compDates.isNotEmpty ? compDates.last : null;
        _selectedDateClimatisation = climDates.isNotEmpty ? climDates.last : null;
      });
    } catch (e) {
      print('Erreur récupération des dates disponibles : $e');
    }
  }


  Future<List<String>> _fetchDates(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> datesJson = json.decode(response.body);
      return datesJson.map((e) => e.toString()).toList();
    } else {
      throw Exception('Erreur récupération dates: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> _fetchAllDataForType(String type, List<String> dates) async {
    List<dynamic> allData = [];
    final baseUrl = 'http://10.0.2.2:3000/api/energy';

    for (var date in dates) {
      try {
        final rawData = await _fetchData('$baseUrl/$type/$date');
        allData.addAll(rawData);
      } catch (e) {
        print('Erreur chargement $type $date : $e');
      }
    }

    allData.sort((a, b) => a['ts'].compareTo(b['ts']));
    return allData;
  }

  Future<List<dynamic>> _fetchData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erreur de chargement des données');
    }
  }

  Future<void> _fetchEnergyData() async {
    setState(() => _isLoading = true);

    try {
      final tgbtData = _selectedDateTGBT != null
          ? await _fetchData('http://10.0.2.2:3000/api/energy/tgbt/$_selectedDateTGBT')
          : [];
      final compData = _selectedDateCompresseurs != null
          ? await _fetchData('http://10.0.2.2:3000/api/energy/compresseurs/$_selectedDateCompresseurs')
          : [];
      final climData = _selectedDateClimatisation != null
          ? await _fetchData('http://10.0.2.2:3000/api/energy/climatisation/$_selectedDateClimatisation')
          : [];

      setState(() {
        _tgbt4h = _aggregateDataBy4Hours(tgbtData);
        _compress4h = _aggregateDataBy4Hours(compData);
        _clim4h = _aggregateDataBy4Hours(climData);

        _energyData = {
          'tgbtDaily': _calculateTotalConsumption(_tgbt4h),
          'compressDaily': _calculateTotalConsumption(_compress4h),
          'climDaily': _calculateTotalConsumption(_clim4h),
          'tgbtPower': _calculateCurrentPower(_tgbt4h),
          'compressPower': _calculateCurrentPower(_compress4h),
          'climPower': _calculateCurrentPower(_clim4h),
          'lastUpdate': DateTime.now(),
        };

        _temperatures = _calculateTemperaturesFromClim(_clim4h);
      });
    } catch (e) {
      print('Erreur de récupération des données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  List<Map<String, dynamic>> _aggregateDataBy4Hours(List<dynamic> rawData) {
    if (rawData.isEmpty) return [];

    rawData.sort((a, b) => a['ts'].compareTo(b['ts']));
    List<Map<String, dynamic>> aggregatedData = [];
    DateTime? currentWindowStart;
    double sum = 0;
    int count = 0;
    double firstValue = 0;

    for (var i = 0; i < rawData.length; i++) {
      final item = rawData[i];
      final timestamp = DateTime.fromMillisecondsSinceEpoch(item['ts']);
      final value = double.parse(item['value']);

      if (currentWindowStart == null) {
        currentWindowStart = timestamp;
        firstValue = value;
      }

      if (timestamp.difference(currentWindowStart).inHours < 4) {
        sum += value;
        count++;
      } else {
        aggregatedData.add({
          'ts': currentWindowStart.millisecondsSinceEpoch,
          'value': (sum / count).toString(),
          'consumption': double.parse(rawData[i - 1]['value']) - firstValue,
        });

        currentWindowStart = timestamp;
        firstValue = value;
        sum = value;
        count = 1;
      }
    }

    if (count > 0) {
      aggregatedData.add({
        'ts': currentWindowStart!.millisecondsSinceEpoch,
        'value': (sum / count).toString(),
        'consumption': double.parse(rawData.last['value']) - firstValue,
      });
    }

    return aggregatedData;
  }

  Map<String, double> _groupConsumptionByMonth(List<dynamic> data) {
    Map<String, double> grouped = {};
    for (var item in data) {
      if (item['ts'] == null || item['consumption'] == null) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(item['ts']);
      final monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      grouped[monthKey] = (grouped[monthKey] ?? 0) + item['consumption'];
    }
    return grouped;
  }

Map<String, double> _calculateTemperaturesFromClim(List<dynamic> climData) {
    if (climData.isEmpty) {
      return {'zone1': 22.0, 'zone2': 22.0, 'zone3': 22.0};
    }

    // Calcul de la consommation totale
    double totalConsumption = _calculateTotalConsumption(climData);

    // Base de température et coefficient
    const baseTemp = 22.0;
    const maxTemp = 28.0;
    const minTemp = 18.0;

    // Calcul du facteur de température (0 à 1) basé sur la consommation totale
    // On suppose qu'une consommation de 50 kWh donne une température max
    final tempFactor = (totalConsumption / 50.0).clamp(0.0, 1.0);

    // Température centrale
    final centerTemp = baseTemp + (maxTemp - baseTemp) * tempFactor;

    return {
      'zone1': centerTemp.clamp(minTemp, maxTemp),
      'zone2': (centerTemp * 0.9).clamp(minTemp, maxTemp),
      'zone3': (centerTemp * 1.1).clamp(minTemp, maxTemp),
    };
  }

  double _calculateTotalConsumption(List<dynamic> aggregatedData) {
    if (aggregatedData.isEmpty) return 0.0;
    double total = 0;
    for (var window in aggregatedData) {
      total += window['consumption'] ?? 0;
    }
    return total;
  }


  double _calculateCurrentPower(List<dynamic> data) {
    if (data.isEmpty) return 0.0;
    return double.tryParse(data.last['value'].toString()) ?? 0.0;
  }

  String _formatLastUpdate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours > 0) return 'Dernière mise à jour il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Dernière mise à jour il y a ${diff.inMinutes}min';
    return 'Dernière mise à jour à l\'instant';
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
            Image.asset(
              'assets/brain71.png',
              height: 36,
            ),
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
      body: _showHistory ? _buildHistoryView() : _buildHomeView(),
    );
  }

  Widget _buildHomeView() {
    return RefreshIndicator(
      onRefresh: _fetchEnergyData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Consommation d\'énergie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.blueAccent),
                    onPressed: () => setState(() => _showHistory = true),
                    tooltip: 'Voir historique',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: "TGBT",
                icon: Icons.electric_bolt,
                items: [
                  _buildEnergyItem(
                    title: "TGBT - Conso du jour",
                    value: "${_energyData['tgbtDaily'].toStringAsFixed(1)} kWh",
                    subtitle: _formatLastUpdate(_energyData['lastUpdate']),
                    icon: Icons.show_chart,
                  ),
                ],
                color: Colors.red,
                data: _tgbt4h,
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: "Compresseurs",
                icon: Icons.compress,
                items: [
                  _buildEnergyItem(
                    title: "Compresseurs - Conso du jour",
                    value: "${_energyData['compressDaily'].toStringAsFixed(1)} kWh",
                    subtitle: _formatLastUpdate(_energyData['lastUpdate']),
                    icon: Icons.bar_chart,
                  ),
                ],
                color: Colors.green,
                data: _compress4h,
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: "Climatisation",
                icon: Icons.ac_unit,
                items: [
                  _buildEnergyItem(
                    title: "Climatisation - Conso du jour",
                    value: "${_energyData['climDaily'].toStringAsFixed(1)} kWh",
                    subtitle: _formatLastUpdate(_energyData['lastUpdate']),
                    icon: Icons.thermostat,
                  ),
                ],
                color: Colors.blue,
                data: _clim4h,
              ),
              const SizedBox(height: 16),

              // Section Conso instantanée modifiée
              _buildInstantConsumptionSection(),
              const SizedBox(height: 24),

              _buildSectionTitle(
                title: 'Températures des zones',
                icon: Icons.thermostat_auto,
              ),
              _buildTemperatureZonesCard(),
              const SizedBox(height: 16),
              _buildTemperatureGaugeCard(),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Voir l\'historique complet'),
                    onPressed: () => setState(() => _showHistory = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Nouvelle méthode pour la section Conso instantanée
  Widget _buildInstantConsumptionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "Conso instantanée",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstantConsumptionItem(
              "TGBT",
              _energyData['tgbtPower'],
              Colors.red,
              _tgbt4h,
              Icons.electric_bolt,
            ),
            const SizedBox(height: 16),
            _buildInstantConsumptionItem(
              "Compresseurs",
              _energyData['compressPower'],
              Colors.green,
              _compress4h,
              Icons.power,
            ),
            const SizedBox(height: 16),
            _buildInstantConsumptionItem(
              "Climatisation",
              _energyData['climPower'],
              Colors.blue,
              _clim4h,
              Icons.air,
            ),
          ],
        ),
      ),
    );
  }

  // Nouvelle méthode pour chaque item de consommation instantanée
  Widget _buildInstantConsumptionItem(
      String title,
      double power,
      Color color,
      List<dynamic> data,
      IconData icon,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$title - Conso instantanée",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                  Text(
                    "${power.toStringAsFixed(2)} kW",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: data.isEmpty ? 1 : data.length - 1,
                minY: 0,
                maxY: _calculateMaxPower(data) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: _generatePowerSpots(data),
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    belowBarData: BarAreaData(show: false),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateMaxPower(List<dynamic> data) {
    if (data.isEmpty) return 1.0;
    double max = 0;
    for (var item in data) {
      final value = double.tryParse(item['value'].toString()) ?? 0.0;
      if (value > max) max = value;
    }
    return max > 0 ? max : 1.0;
  }

  List<FlSpot> _generatePowerSpots(List<dynamic> data) {
    if (data.isEmpty) return [FlSpot(0, 0)];

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      final power = double.tryParse(data[i]['value'].toString()) ?? 0.0;
      spots.add(FlSpot(i.toDouble(),power));
    }
    return spots;
  }


  Widget _buildHistoryView() {
    DateTime? getLatestDate(List<Map<String, dynamic>> data) {
      if (data.isEmpty) return null;
      List<DateTime> dates = data.map((e) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(e['ts'] as int);
        } catch (_) {
          return DateTime(1970);
        }
      }).toList();
      dates.sort();
      return dates.isNotEmpty ? dates.last : null;
    }

    final latestDateTgbt = getLatestDate(_tgbt4h);
    if (latestDateTgbt == null) {
      // Si aucune donnée disponible, afficher un message simple
      return Center(child: Text("Pas de données disponibles"));
    }

    // Calcul des mois actuel et précédent à partir des données
    final currentMonth = "${latestDateTgbt.year}-${latestDateTgbt.month.toString().padLeft(2, '0')}";
    final previousMonthDate = DateTime(latestDateTgbt.year, latestDateTgbt.month - 1);
    final previousMonth = "${previousMonthDate.year}-${previousMonthDate.month.toString().padLeft(2, '0')}";

    int daysInMonth(DateTime date) {
      final beginningNextMonth = (date.month < 12)
          ? DateTime(date.year, date.month + 1, 1)
          : DateTime(date.year + 1, 1, 1);
      return beginningNextMonth.subtract(const Duration(days: 1)).day;
    }

    final totalDaysCurrentMonth = daysInMonth(latestDateTgbt);

    // Regroupements des consommations par mois
    final tgbtByMonth = _groupConsumptionByMonth(_tgbt4h);
    final tgbtCurrentMonth = tgbtByMonth[currentMonth] ?? 0.0;
    final tgbtPreviousMonth = tgbtByMonth[previousMonth] ?? 0.0;

    final climByMonth = _groupConsumptionByMonth(_clim4h);
    final climCurrentMonth = climByMonth[currentMonth] ?? 0.0;
    final climPreviousMonth = climByMonth[previousMonth] ?? 0.0;

    final compressByMonth = _groupConsumptionByMonth(_compress4h);
    final compressCurrentMonth = compressByMonth[currentMonth] ?? 0.0;
    final compressPreviousMonth = compressByMonth[previousMonth] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historique de consommation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showHistory = false),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildHistoryCard(
            title: "TGBT",
            items: [
              _buildHistoryItem("Mois dernier", "${tgbtPreviousMonth.toStringAsFixed(1)} kWh"),
              _buildHistoryItem("Ce mois-ci", "${tgbtCurrentMonth.toStringAsFixed(1)} kWh"),
              _buildHistoryItem(
                "Moyenne journalière",
                (tgbtCurrentMonth / totalDaysCurrentMonth).toStringAsFixed(1) + " kWh",
              ),
            ],
            color: Colors.red,
            total: "${_energyData['tgbtDaily'].toStringAsFixed(1)} kWh",
          ),

          const SizedBox(height: 16),

          _buildHistoryCard(
            title: "Climatisation",
            items: [
              _buildHistoryItem("Mois dernier", "${climPreviousMonth.toStringAsFixed(1)} kWh"),
              _buildHistoryItem("Ce mois-ci", "${climCurrentMonth.toStringAsFixed(1)} kWh"),
              _buildHistoryItem(
                "Moyenne journalière",
                (climCurrentMonth / totalDaysCurrentMonth).toStringAsFixed(1) + " kWh",
              ),
            ],
            color: Colors.blue,
            total: "${_energyData['climDaily'].toStringAsFixed(1)} kWh",
          ),

          const SizedBox(height: 16),

          _buildHistoryCard(
            title: "Compresseurs",
            items: [
              _buildHistoryItem("Mois dernier", "${compressPreviousMonth.toStringAsFixed(1)} kWh"),
              _buildHistoryItem("Ce mois-ci", "${compressCurrentMonth.toStringAsFixed(1)} kWh"),
              _buildHistoryItem(
                "Moyenne journalière",
                (compressCurrentMonth / totalDaysCurrentMonth).toStringAsFixed(1) + " kWh",
              ),
            ],
            color: Colors.green,
            total: "${_energyData['compressDaily'].toStringAsFixed(1)} kWh",
          ),

          const SizedBox(height: 20),

          const Text(
            'Consommation mois par mois',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: _energyData['tgbtDaily'] / 1000,
                        color: Colors.red,
                        width: 16,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: _energyData['climDaily'] / 1000,
                        color: Colors.blue,
                        width: 16,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: _energyData['compressDaily'] / 1000,
                        color: Colors.green,
                        width: 16,
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['TGBT', 'Climatisation', 'Compresseurs'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}k');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: ElevatedButton(
              onPressed: () => setState(() => _showHistory = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Retour à l\'accueil'),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[700], size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
    required Color color,
    required List<dynamic> data,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items,
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: data.length.toDouble() - 1,
                  minY: 0,
                  maxY: _getMaxYValue(data),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateRealSpots(data),
                      isCurved: true,
                      color: color,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.2),
                      ),
                      dotData: FlDotData(show: true), // Active les points visibles
                    ),
                  ],
                ),
              )

            ),
          ],
        ),
      ),
    );
  }

  double _getMaxYValue(List<dynamic> data) {
    if (data.isEmpty) return 100.0;
    double max = 0;
    for (var item in data) {
      final value = double.parse(item['value']);
      if (value > max) max = value;
    }
    return max * 1.1; // Ajoute une marge de 10%
  }

  List<FlSpot> _generateRealSpots(List<dynamic> data) {
    return List<FlSpot>.generate(data.length, (index) {
      final value = double.tryParse(data[index]['value'].toString()) ?? 0.0;
      return FlSpot(index.toDouble(), value);
    });
  }



  Widget _buildEnergyItem({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.blueGrey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureZonesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildZoneItem("Températures Zone (3D/5E/SG)"),
            const Divider(height: 24, thickness: 0.5),
            _buildZoneItem("Températures Zone (2D/4E/SG)"),
            const Divider(height: 24, thickness: 0.5),
            _buildZoneItem("Températures Zone (1D/3E/SG)"),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneItem(String text) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.blueGrey, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    );
  }

  Widget _buildTemperatureGaugeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Températures actuelles",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTemperatureGauge("Zone 1", "${_temperatures['zone1']?.toStringAsFixed(1)}°C", Colors.blue[400]!),
                _buildTemperatureGauge("Zone 2", "${_temperatures['zone2']?.toStringAsFixed(1)}°C", Colors.orange[400]!),
                _buildTemperatureGauge("Zone 3", "${_temperatures['zone3']?.toStringAsFixed(1)}°C", Colors.red[400]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureGauge(String zone, String temp, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 8),
          ),
          child: Center(
            child: Text(
              temp,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          zone,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blueGrey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required List<Widget> items,
    required Color color,
    required String total,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  total,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}