import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../sabloane/statistici_sablon.dart';
import '../service/statistici_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticiService _statisticiService = StatisticiService();

  late Future<StatisticiSablon> _statisticiFuture;

  final List<Color> _culoriCategorii = const [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _incarcaStatistici();
  }

  void _incarcaStatistici() {
    _statisticiFuture = _statisticiService.getStatistici();
  }

  Future<void> _refreshStatistici() async {
    setState(() {
      _incarcaStatistici();
    });

    await _statisticiFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistici turistice'),
        actions: [
          IconButton(
            tooltip: 'Actualizează',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _incarcaStatistici();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<StatisticiSablon>(
        future: _statisticiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _errorWidget(snapshot.error);
          }

          final statistici = snapshot.data ?? StatisticiSablon.empty();

          return RefreshIndicator(
            onRefresh: _refreshStatistici,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Prezentare generală',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                _summaryCards(statistici),

                const SizedBox(height: 28),

                _sectionTitle(
                  icon: Icons.pie_chart,
                  title: 'Cele mai populare categorii',
                ),

                const SizedBox(height: 14),

                _categoriesChart(statistici),

                const SizedBox(height: 28),

                _sectionTitle(
                  icon: Icons.location_city,
                  title: 'Cele mai apreciate județe',
                ),

                const SizedBox(height: 14),

                _countiesChart(statistici),

                const SizedBox(height: 28),

                _sectionTitle(
                  icon: Icons.emoji_events,
                  title: 'Clasamentul județelor',
                ),

                const SizedBox(height: 12),

                _countiesRanking(statistici),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCards(StatisticiSablon statistici) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard(
          title: 'Locații',
          value: statistici.totalLocatii.toString(),
          icon: Icons.place,
          color: Colors.blue,
        ),
        _statCard(
          title: 'Recenzii',
          value: statistici.totalRecenzii.toString(),
          icon: Icons.rate_review,
          color: Colors.orange,
        ),
        _statCard(
          title: 'Rating mediu',
          value: statistici.ratingMediu.toStringAsFixed(2),
          icon: Icons.star,
          color: Colors.amber.shade700,
        ),
        _statCard(
          title: 'Categorii',
          value: statistici.locatiiPeCategorie.length.toString(),
          icon: Icons.category,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _categoriesChart(StatisticiSablon statistici) {
    final categorii = statistici.categoriiPopulare.take(6).toList();

    if (categorii.isEmpty) {
      return _emptyCard('Nu există suficiente date despre categorii.');
    }

    final total = categorii.fold<int>(
      0,
      (suma, element) => suma + element.value,
    );

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 230,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 42,
                  sections: List.generate(categorii.length, (index) {
                    final categorie = categorii[index];
                    final procent = total == 0
                        ? 0
                        : categorie.value / total * 100;

                    return PieChartSectionData(
                      value: categorie.value.toDouble(),
                      color: _culoriCategorii[index % _culoriCategorii.length],
                      radius: 72,
                      title: '${procent.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ...List.generate(categorii.length, (index) {
              final categorie = categorii[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color:
                            _culoriCategorii[index % _culoriCategorii.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        categorie.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${categorie.value} locații',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _countiesChart(StatisticiSablon statistici) {
    final judete = statistici.judeteApreciate.take(5).toList();

    if (judete.isEmpty) {
      return _emptyCard('Nu există județe cu recenzii suficiente.');
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 22, 18, 12),
        child: SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: 5,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final judet = judete[group.x];

                    return BarTooltipItem(
                      '${judet.key}\n'
                      '${rod.toY.toStringAsFixed(2)} ⭐',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= judete.length) {
                        return const SizedBox.shrink();
                      }

                      final numeJudet = judete[index].key;
                      final textScurt = numeJudet.length <= 7
                          ? numeJudet
                          : '${numeJudet.substring(0, 6)}.';

                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          textScurt,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(judete.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: judete[index].value,
                      width: 24,
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _countiesRanking(StatisticiSablon statistici) {
    final judete = statistici.judeteApreciate.take(5).toList();

    if (judete.isEmpty) {
      return _emptyCard('Clasamentul va apărea după adăugarea recenziilor.');
    }

    return Card(
      elevation: 3,
      child: Column(
        children: List.generate(judete.length, (index) {
          final judet = judete[index];
          final nrRecenzii = statistici.recenziiPeJudet[judet.key] ?? 0;

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(
                  judet.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$nrRecenzii '
                  '${nrRecenzii == 1 ? 'recenzie' : 'recenzii'}',
                ),
                trailing: Text(
                  '${judet.value.toStringAsFixed(2)} ⭐',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (index < judete.length - 1) const Divider(height: 1),
            ],
          );
        }),
      ),
    );
  }

  Widget _emptyCard(String mesaj) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            mesaj,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _errorWidget(Object? eroare) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 55),
            const SizedBox(height: 12),
            const Text(
              'Statisticile nu au putut fi încărcate.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              eroare?.toString() ?? 'Eroare necunoscută',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _incarcaStatistici();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Încearcă din nou'),
            ),
          ],
        ),
      ),
    );
  }
}
