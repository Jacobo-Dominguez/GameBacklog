import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/backlog_provider.dart';
import '../../../core/theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Consumer<BacklogProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          final genres = provider.getGenresDistribution();
          final monthlyHours = provider.getHoursPerMonth();
          final avgTime = provider.getAverageCompletionTime();
          final totalHoursVal = provider.getTotalHours();
          final totalHours = totalHoursVal.toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    'Estadísticas de Juego',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick summary cards
                _buildQuickSummary(context, provider, totalHours, avgTime),
                const SizedBox(height: 32),

                // Charts
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
        _buildSummaryCard(context, 'Total Juegos', provider.getTotalGames().toString(), Icons.videogame_asset_rounded, AppColors.accentCyan),
        _buildSummaryCard(context, 'Horas Totales', totalHours, Icons.access_time_filled_rounded, AppColors.accentAmber),
        _buildSummaryCard(context, 'Media / Juego', '${avgTime.toStringAsFixed(1)}h', Icons.assessment_rounded, AppColors.accentTeal),
        _buildSummaryCard(context, 'Completados', (provider.stats['completed'] ?? 0).toString(), Icons.check_circle_rounded, AppColors.accentPurple),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 13,
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
      AppColors.accentCyan,
      AppColors.accentPurple,
      AppColors.accentAmber,
      AppColors.accentTeal,
      AppColors.accentRose,
      AppColors.accentMagenta,
      const Color(0xFF64FFDA),
      const Color(0xFFFF6E40),
    ];

    int i = 0;
    genres.forEach((name, count) {
      if (i < 8) {
        sections.add(PieChartSectionData(
          color: colors[i % colors.length],
          value: count.toDouble(),
          title: '$count',
          radius: 55,
          titleStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.bgDark,
          ),
        ));
      }
      i++;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Géneros Favoritos',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 45,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(sections.length, (index) {
              final genreName = genres.keys.elementAt(index);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    genreName,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
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
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Text('Sin datos de actividad mensual', style: GoogleFonts.inter(color: AppColors.textMuted)),
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
            gradient: AppColors.primaryGradient,
            width: 22,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxHours * 1.1,
              color: AppColors.bgSurface,
            ),
          ),
        ],
      ));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horas jugadas por mes',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxHours * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.bgElevated,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}h',
                        GoogleFonts.inter(
                          color: AppColors.accentCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= lastMonths.length) return const SizedBox.shrink();
                        final parts = lastMonths[index].split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${parts[1]}/${parts[0].substring(2)}',
                            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
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
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxHours / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFF2A2A4A),
                    strokeWidth: 1,
                  ),
                ),
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
          colors: [
            AppColors.accentCyan.withOpacity(0.08),
            AppColors.accentPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Otros Hitos',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          _buildStatRow(Icons.timer_rounded, 'Juego más largo', '${longestTime.toStringAsFixed(1)}h', AppColors.accentAmber),
          Divider(height: 24, color: AppColors.accentCyan.withOpacity(0.1)),
          _buildStatRow(Icons.calendar_today_rounded, 'Backlog creado el', 
            '${provider.backlogEntries.isEmpty ? "-" : _formatDate(provider.backlogEntries.map((e) => e.addedDate).reduce((a, b) => a.isBefore(b) ? a : b))}',
            AppColors.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
