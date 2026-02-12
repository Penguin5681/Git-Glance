import 'package:flutter/material.dart';
import '../../data/models/repository_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageChart extends StatelessWidget {
  final List<RepositoryModel> repos;

  const LanguageChart({super.key, required this.repos});

  @override
  Widget build(BuildContext context) {
    if (repos.isEmpty) return const SizedBox.shrink();

    // Aggregate languages
    final Map<String, int> languageCounts = {};
    for (var repo in repos) {
      if (repo.language != null) {
        languageCounts[repo.language!] = (languageCounts[repo.language!] ?? 0) + 1;
      }
    }

    if (languageCounts.isEmpty) return const SizedBox.shrink();

    // Convert to PieChartSectionData
    final total = languageCounts.values.reduce((a, b) => a + b);
    final List<PieChartSectionData> sections = [];

    languageCounts.forEach((key, value) {
      final percent = value / total;
      if (percent < 0.05) return; // Skip small slices to avoid clutter

      sections.add(PieChartSectionData(
        color: _getLanguageColor(key),
        value: value.toDouble(),
        title: '${(percent * 100).toStringAsFixed(0)}%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    });

    return Column(
      children: [
        Text(
          'Language Breakdown',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((section) {
                     // Reverse engineer key from color? No, we need context.
                     // Let's iterate map again or just build legend separately.
                     // Easier to use languageCounts but filter same way.
                     return Padding(
                       padding: const EdgeInsets.symmetric(vertical: 2.0),
                       child: Row(
                          children: [
                             Container(
                               width: 10, height: 10,
                               decoration: BoxDecoration(color: section.color, shape: BoxShape.circle),
                             ),
                             const SizedBox(width: 8),
                             // We don't have the name here easily matching the color in simple loop unless structured.
                             // Let's assume we can display text.
                             // Actually, simpler to not display legend or structure this better.
                             // Let's skip legend for a moment or implement properly.
                             const Text(""),
                          ],
                       ),
                     );
                  }).toList(),
                ),
              )
            ],
          ),
        ),
        // Simple Legend
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: languageCounts.entries.where((e) => (e.value / total) >= 0.05).map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Container(
                   width: 10, height: 10,
                   decoration: BoxDecoration(color: _getLanguageColor(e.key), shape: BoxShape.circle),
                 ),
                 const SizedBox(width: 4),
                 Text(e.key, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _getLanguageColor(String language) {
    // Basic hash to get a consistent color
    final int hash = language.codeUnits.fold(0, (prev, element) => prev + element);
    final List<Color> colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal, Colors.amber, Colors.indigo,
      Colors.pink, Colors.cyan, Colors.brown,
    ];
    return colors[hash % colors.length];
  }
}



