import 'package:flutter/material.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../models/prediction.dart';
import 'analysis_result_screen.dart';
import '../widgets/history_chart_widget.dart';

class ArchivesScreen extends StatefulWidget {
  const ArchivesScreen({super.key});

  @override
  State<ArchivesScreen> createState() => ArchivesScreenState();
}

class ArchivesScreenState extends State<ArchivesScreen> {
  List<Prediction> _allHistory = [];
  List<Prediction> _filteredHistory = [];
  String? _selectedBreedFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final db = DatabaseHelper();
    final history = await db.getHistory();

    if (mounted) {
      setState(() {
        _allHistory = history;
        _isLoading = false;

        if (_selectedBreedFilter != null) {
          _filteredHistory = _allHistory
              .where((p) => p.breedName == _selectedBreedFilter)
              .toList();
        } else {
          _filteredHistory = history;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    final h =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? "PM" : "AM";
    final m = date.minute.toString().padLeft(2, '0');
    return "${months[date.month - 1]} ${date.day}, $h:$m $ampm";
  }

  void _onBreedSelected(String? breed) {
    setState(() {
      _selectedBreedFilter = breed;
      if (breed == null) {
        _filteredHistory = _allHistory;
      } else {
        _filteredHistory =
            _allHistory.where((p) => p.breedName == breed).toList();
      }
    });
  }

  Future<void> _deleteItem(String id) async {
    await DatabaseHelper().deletePrediction(id);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Scan Archives',
          style:
              TextStyle(color: Color(0xFF3D3D3D), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        centerTitle: true,
        elevation: 0,
      ),
      // Use CustomScrollView for full-page scrolling
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8A89B)))
          : CustomScrollView(
              slivers: [
                // CHART SECTION (Scrolls with page)
                if (_allHistory.isNotEmpty)
                  SliverToBoxAdapter(
                    child: DetectionInsightsWidget(
                      fullHistory: _allHistory,
                      selectedBreed: _selectedBreedFilter,
                      onBreedSelected: _onBreedSelected,
                    ),
                  ),

                // LIST HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          _selectedBreedFilter != null
                              ? "Showing $_selectedBreedFilter Scans"
                              : "Recent Scans",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB8A3A3),
                            letterSpacing: 1,
                          ),
                        ),
                        if (_selectedBreedFilter != null) const Spacer(),
                        if (_selectedBreedFilter != null)
                          GestureDetector(
                            onTap: () => _onBreedSelected(null),
                            child: const Text("Show All",
                                style: TextStyle(color: Color(0xFFE8A89B))),
                          ),
                      ],
                    ),
                  ),
                ),

                // HISTORY LIST
                _filteredHistory.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                _allHistory.isEmpty
                                    ? "No scans yet"
                                    : "No ${_selectedBreedFilter ?? ''} scans found",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _filteredHistory[index];
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.redAccent,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteItem(item.id),
                              child: _buildHistoryCard(item),
                            );
                          },
                          childCount: _filteredHistory.length,
                        ),
                      ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
    );
  }

  Widget _buildHistoryCard(Prediction item) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 6), // Adjusted margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalysisResultScreen(
                  detectedBreed: item.breedName,
                  confidence: item.confidence,
                  imagePath: item.imagePath,
                  similarBreeds:
                      item.similarBreeds, // <-- CORRECTED: Pass directly
                  gatekeeperConfidence: item.gatekeeperConfidence,
                  fromHistory: true,
                  existingId: item.id,
                  initialPersonality: item.personality,
                ),
              ),
            );
            refresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[100],
                    child: Image.file(
                      File(item.imagePath),
                      fit: BoxFit.cover,
                      cacheWidth: 200, // Limit memory usage for assets
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.breedName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D3D3D),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDate(item.timestamp),
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            '${(item.confidence * 100).toInt()}%',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (item.personality != null &&
                          item.personality!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B73FF).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFF6B73FF).withAlpha(51)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome,
                                  size: 10, color: Color(0xFF6B73FF)),
                              const SizedBox(width: 4),
                              Text(
                                item.personality!,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B73FF)),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Color(0xFFE8A89B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
