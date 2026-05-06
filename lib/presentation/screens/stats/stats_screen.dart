import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/backlog_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BacklogProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final genres = provider.getGenresDistribution();
          final monthlyHours = provider.getHoursPerMonth();
          final avgTime = provider.getAverageCompletionTime();
          final totalMinutes = provider.getTotalMinutesPlayed();
          final totalHours = (totalMinutes / 60).toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estadísticas de Juego',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Resumen rápido
                _buildQuickSummary(context, provider, totalHours, avgTime),
                const SizedBox(height: 32),

                // Gráficos
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _buildGenrePieChart(context, genres)),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildMonthlyBarChart(context, monthlyHours)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildGenrePieChart(context, genres),
                          const SizedBox(height: 24),
                          _buildMonthlyBarChart(context, monthlyHours),
                        ],
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 32),
                _buildExtraStats(context, provider),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickSummary(BuildContext context, BacklogProvider provider, String totalHours, double avgTime) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildSummaryCard(
          context,
          'Total Juegos',
          provider.getTotalGames().toString(),
          Icons.videogame_asset,
          Colors.blue,
        ),
        _buildSummaryCard(
          context,
          'Horas Totales',
          totalHours,
          Icons.access_time_filled,
          Colors.orange,
        ),
        _buildSummaryCard(
          context,
          'Media / Juego',
          '${avgTime.toStringAsFixed(1)}h',
          Icons.assessment,
          Colors.green,
        ),
        _buildSummaryCard(
          context,
          'Completados',
          (provider.stats['completed'] ?? 0).toString(),
          Icons.check_circle,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenrePieChart(BuildContext context, Map<String, int> genres) {
    if (genres.isEmpty) return const SizedBox.shrink();

    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.amber,
      Colors.cyan,
      Colors.pink,
    ];

    int i = 0;
    genres.forEach((name, count) {
      if (i < 8) {
        sections.add(PieChartSectionData(
          color: colors[i % colors.length],
          value: count.toDouble(),
          title: '$count',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ));
      }
      i++;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Géneros Favoritos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Leyenda
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(sections.length, (index) {
              final genreName = genres.keys.elementAt(index);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    genreName,
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(BuildContext context, Map<String, double> monthlyHours) {
    if (monthlyHours.isEmpty) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: const Text('Sin datos de actividad mensual', style: TextStyle(color: Colors.grey)),
      );
    }

    final sortedMonths = monthlyHours.keys.toList()..sort();
    final lastMonths = sortedMonths.length > 6 
        ? sortedMonths.sublist(sortedMonths.length - 6) 
        : sortedMonths;

    final List<BarChartGroupData> barGroups = [];
    double maxHours = 5;

    for (int i = 0; i < lastMonths.length; i++) {
      final hours = monthlyHours[lastMonths[i]]!;
      if (hours > maxHours) maxHours = hours;
      
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: Colors.blueAccent,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxHours * 1.1,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      ));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horas jugadas por mes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxHours * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= lastMonths.length) return const SizedBox.shrink();
                        // Formato YYYY-MM -> MM/YY
                        final parts = lastMonths[index].split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${parts[1]}/${parts[0].substring(2)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}h',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraStats(BuildContext context, BacklogProvider provider) {
    final longestTime = provider.getLongestGameTime();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Otros Hitos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          _buildStatRow(Icons.timer, 'Juego más largo', '${longestTime}h'),
          const Divider(height: 24, color: Colors.white10),
          _buildStatRow(Icons.calendar_today, 'Backlog creado el', 
            '${provider.backlogEntries.isEmpty ? "-" : _formatDate(provider.backlogEntries.map((e) => e.addedDate).reduce((a, b) => a.isBefore(b) ? a : b))}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
