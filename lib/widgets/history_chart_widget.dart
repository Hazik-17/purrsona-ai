import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/prediction.dart';
import '../services/json_data_service.dart';
import '../screens/breed_info_screen.dart';
import '../models/breed.dart';

enum TimeRange { today, week, month, all }

/// Shows a bar chart of which breeds we found most, with tips for each breed
class DetectionInsightsWidget extends StatefulWidget {
  final List<Prediction> fullHistory;
  final String? selectedBreed;
  final Function(String?) onBreedSelected;

  const DetectionInsightsWidget({
    super.key,
    required this.fullHistory,
    required this.selectedBreed,
    required this.onBreedSelected,
  });

  @override
  State<DetectionInsightsWidget> createState() =>
      _DetectionInsightsWidgetState();
}

class _DetectionInsightsWidgetState extends State<DetectionInsightsWidget> {
  TimeRange _selectedTimeRange = TimeRange.all;
  bool _startAnimation = false;

  // Cached stats for the current view
  List<Map<String, dynamic>> _currentStats = [];
  String _insightMessage = "Welcome to your insights!";
  String _smartRecommendation = "";

  //to store the hover text
  String? _hoveredStat;

  @override
  void initState() {
    super.initState();
    _calculateStats();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _startAnimation = true);
    });
  }

  @override
  void didUpdateWidget(covariant DetectionInsightsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullHistory != widget.fullHistory) {
      _calculateStats();
    }
  }

  // Counts which breeds show up most and creates messages about them
  void _calculateStats() {
    final now = DateTime.now();

    final filteredHistory = widget.fullHistory.where((p) {
      switch (_selectedTimeRange) {
        case TimeRange.today:
          return p.timestamp.year == now.year &&
              p.timestamp.month == now.month &&
              p.timestamp.day == now.day;
        case TimeRange.week:
          return p.timestamp.isAfter(now.subtract(const Duration(days: 7)));
        case TimeRange.month:
          return p.timestamp.isAfter(now.subtract(const Duration(days: 30)));
        case TimeRange.all:
          return true;
      }
    }).toList();

    final Map<String, int> counts = {};
    final Map<String, double> confidenceSum = {};

    for (var p in filteredHistory) {
      counts[p.breedName] = (counts[p.breedName] ?? 0) + 1;
      confidenceSum[p.breedName] =
          (confidenceSum[p.breedName] ?? 0.0) + p.confidence;
    }

    final stats = counts.entries.map((e) {
      return {
        'breedName': e.key,
        'count': e.value,
        'avgConfidence': (confidenceSum[e.key]! / e.value),
      };
    }).toList();

    stats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    setState(() {
      _currentStats = stats;  // Show all breeds, no limit
      _generateInsight(stats, filteredHistory.length);
      _generateSmartRecommendation(stats);
    });
  }

  // Makes a friendly message about the top breed
  void _generateInsight(List<Map<String, dynamic>> stats, int totalScans) {
    if (stats.isEmpty) {
      _insightMessage = "No scans found for this period. Start exploring!";
      return;
    }

    final topBreed = stats.first['breedName'] as String;
    final topCount = stats.first['count'] as int;

    if (_selectedTimeRange == TimeRange.today) {
      _insightMessage =
          "You've spotted $totalScans cats today! mostly $topBreed.";
    } else if (topCount > (totalScans * 0.5)) {
      _insightMessage =
          "You have a clear favorite! $topBreed makes up over 50% of your scans.";
    } else {
      _insightMessage =
          "$topBreed is your most frequently detected breed recently.";
    }
  }

  // Gives breed-specific tips based on what breeds we found
  void _generateSmartRecommendation(List<Map<String, dynamic>> stats) {
    if (stats.isEmpty) {
      _smartRecommendation = "";
      return;
    }

    final topBreed = stats.first['breedName'] as String;
    final breedLower = topBreed.toLowerCase();

    if (breedLower.contains("abyssinian")) {
      _smartRecommendation =
          "Abyssinians are high-energy climbers! Check out 'Vertical Spaces & Agility Tips'.";
    } else if (breedLower.contains("bengal")) {
      _smartRecommendation =
          "Bengals need lots of stimulation. View our guide on 'Interactive Toys & Puzzles'.";
    } else if (breedLower.contains("birman")) {
      _smartRecommendation =
          "Birmans are prone to weight gain. Learn about 'Portion Control & Healthy Treats'.";
    } else if (breedLower.contains("bombay")) {
      _smartRecommendation =
          "Bombays are heat-seekers! Discover 'Cozy Spots & Winter Care' for your mini-panther.";
    } else if (breedLower.contains("british shorthair")) {
      _smartRecommendation =
          "These sedentary 'teddy bears' need motivation. Read 'Fun Exercises for Lazy Cats'.";
    } else if (breedLower.contains("egyptian mau")) {
      _smartRecommendation =
          "Maus are the fastest domestic cats! Explore 'High-Speed Play Ideas'.";
    } else if (breedLower.contains("maine coon")) {
      _smartRecommendation =
          "Large breeds like Maine Coons need joint support. View 'Health Tips for Giants'.";
    } else if (breedLower.contains("persian")) {
      _smartRecommendation =
          "Persian coats need daily love. Check out our 'Tear Stain & Grooming Guide'.";
    } else if (breedLower.contains("ragdoll")) {
      _smartRecommendation =
          "Ragdolls are strictly indoor cats. Learn about 'Safe Indoor Enrichment'.";
    } else if (breedLower.contains("russian blue")) {
      _smartRecommendation =
          "Russian Blues hate change. Read our tips on 'Reducing Stress & Routine'.";
    } else if (breedLower.contains("siamese")) {
      _smartRecommendation =
          "Siamese are vocal and social! Discover 'Understanding Your Cat's Chatter'.";
    } else if (breedLower.contains("sphynx")) {
      _smartRecommendation =
          "Skin care is vital for hairless breeds. View our 'Oils, Baths & Ear Cleaning Guide'.";
    } else {
      _smartRecommendation =
          "You seem interested in $topBreed! Explore their unique personality traits.";
    }
  }

  // Gets the image path for a breed
  String _getAssetPath(String breedName) {
    final Breed? breedInfo = JsonDataService().getBreedInfo(breedName);
    return breedInfo?.imagePath ?? 'assets/images/placeholder.jpg';
  }

  // Finds the highest count to scale the chart
  int _getMaxCount() {
    if (_currentStats.isEmpty) return 5;
    int max = 0;
    for (var stat in _currentStats) {
      if ((stat['count'] as int) > max) max = stat['count'] as int;
    }
    return max == 0 ? 5 : max;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Time Range Filter
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTimeFilterChip("Today", TimeRange.today),
              const SizedBox(width: 8),
              _buildTimeFilterChip("This Week", TimeRange.week),
              const SizedBox(width: 8),
              _buildTimeFilterChip("This Month", TimeRange.month),
              const SizedBox(width: 8),
              _buildTimeFilterChip("All Time", TimeRange.all),
            ],
          ),
        ),

        // 2. Main Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8A89B).withAlpha((255 * 0.15).round()),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Insight
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CHANGED: This Text updates when you touch the chart
                        Text(
                          _hoveredStat ?? "Detection Frequency",
                          style: TextStyle(
                            // Change color to Pink when hovering, Grey when default
                            color: _hoveredStat != null
                                ? const Color(0xFFD4746B)
                                : const Color(0xFF9E9E9E),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: 400.ms,
                          child: Text(
                            _insightMessage,
                            key: ValueKey(_insightMessage),
                            style: const TextStyle(
                              color: Color(0xFF3D3D3D),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.selectedBreed != null)
                    IconButton(
                      onPressed: () => widget.onBreedSelected(null),
                      icon: const Icon(Icons.refresh_rounded,
                          color: Color(0xFFD4746B)),
                      tooltip: "Clear Filter",
                    ).animate().rotate(),
                ],
              ),
              const SizedBox(height: 32),

              // The Bar Chart
              if (_currentStats.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("No data for this period",
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                // Calculate chart width: ~80px per bar + padding
                SizedBox(
                  height: 220,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: (_currentStats.length * 80)
                              .toDouble()
                              .clamp(300, double.infinity),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _getMaxCount().toDouble() * 1.05,
                              barTouchData: BarTouchData(
                                enabled: false, // CHANGED: Disable floating tooltip
                                touchCallback: (FlTouchEvent event, barTouchResponse) {
                                  // 1. Handle Hover Effect (Update Header Text)
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        barTouchResponse == null ||
                                        barTouchResponse.spot == null) {
                                      _hoveredStat = null;
                                      return;
                                    }
                                    final index = barTouchResponse
                                        .spot!.touchedBarGroupIndex;
                                    final stat = _currentStats[index];
                                    final conf = (stat['avgConfidence'] * 100)
                                        .toStringAsFixed(1);
                                    _hoveredStat =
                                        "${stat['breedName']}: $conf% Confidence";
                                  });

                                  // 2. Handle Tap Selection
                                  if (event is FlTapUpEvent &&
                                      barTouchResponse?.spot != null) {
                                    final index = barTouchResponse!
                                        .spot!.touchedBarGroupIndex;
                                    final breedName =
                                        _currentStats[index]['breedName'];
                                    _handleSelection(breedName);
                                  }
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= _currentStats.length) {
                                        return const SizedBox();
                                      }

                                      final name =
                                          _currentStats[index]['breedName']
                                              as String;
                                      final isSelected =
                                          widget.selectedBreed == name;

                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8,
                                        child: GestureDetector(
                                          onTap: () => _handleSelection(name),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AnimatedContainer(
                                                duration: 300.ms,
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? const Color(0xFFD4746B)
                                                        : Colors.transparent,
                                                    width: 2.0,
                                                  ),
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                              color: const Color(
                                                                      0xFFD4746B)
                                                                  .withAlpha((255 *
                                                                          0.3)
                                                                      .round()),
                                                              blurRadius: 6)
                                                        ]
                                                      : [],
                                                ),
                                                child: ClipOval(
                                                  child: Image.asset(
                                                    _getAssetPath(name),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __,
                                                            ___) =>
                                                        const Icon(Icons.pets,
                                                            size: 16,
                                                            color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              SizedBox(
                                                width: 50,
                                                height: 16,
                                                child: Transform.rotate(
                                                  angle: -0.698, // ~40 degrees
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      color: Color(0xFF3D3D3D),
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= _currentStats.length) {
                                        return const SizedBox();
                                      }

                                      final count =
                                          _currentStats[index]['count'] as int;

                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 4,
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(
                                            color: Color(0xFF3D3D3D),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: _generateBars(),
                            ),
                            swapAnimationDuration: 400.ms,
                            swapAnimationCurve: Curves.easeOutCubic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

        // 3. Smart Recommendation Card (Clickable)
        if (_smartRecommendation.isNotEmpty)
          GestureDetector(
            onTap: () {
              // 2. NAVIGATE TO BREED INFO ON TAP
              if (_currentStats.isNotEmpty) {
                final topBreed = _currentStats.first['breedName'] as String;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BreedInfoScreen(breedName: topBreed),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B73FF).withAlpha((255 * 0.1).round()),
                    Colors.white
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        const Color(0xFF6B73FF).withAlpha((255 * 0.2).round())),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withAlpha((255 * 0.05).round()),
                            blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.lightbulb_rounded,
                        color: Color(0xFF6B73FF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _smartRecommendation,
                      style: const TextStyle(
                        color: Color(0xFF3D3D3D),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: Color(0xFF6B73FF)),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn().slideX(),
          ),
      ],
    );
  }

  // Calculates chart width hint when scrolling needed
  bool _shouldScroll() => _currentStats.length > 5;

  // Makes the filter button for today, week, month, or all time
  Widget _buildTimeFilterChip(String label, TimeRange range) {
    final isSelected = _selectedTimeRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeRange = range;
          _calculateStats();
        });
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4746B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFFD4746B)
                          .withAlpha((255 * 0.3).round()),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Makes the bars for the chart with animations
  List<BarChartGroupData> _generateBars() {
    return List.generate(_currentStats.length, (index) {
      final stat = _currentStats[index];
      final count = (stat['count'] as int).toDouble();
      final breedName = stat['breedName'] as String;

      final isSelected = widget.selectedBreed == breedName;
      final isNoneSelected = widget.selectedBreed == null;
      final double animatedY = _startAnimation ? count : 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: animatedY,
            width: 24,
            gradient: LinearGradient(
              colors: isNoneSelected || isSelected
                  ? [const Color(0xFFE8A89B), const Color(0xFFD4746B)]
                  : [Colors.grey[200]!, Colors.grey[300]!],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxCount().toDouble() * 1.05,
              color: const Color(0xFFF5F5F5),
            ),
          ),
        ],
      );
    });
  }

  // Toggles filter when user clicks a bar
  void _handleSelection(String breedName) {
    if (widget.selectedBreed == breedName) {
      widget.onBreedSelected(null);
    } else {
      widget.onBreedSelected(breedName);
    }
  }
}