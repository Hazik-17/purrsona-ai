// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../models/prediction.dart';
import 'analysis_result_screen.dart';
import '../widgets/history_chart_widget.dart';
import '../widgets/history_card.dart';

/// Shows all past scans with stats and filtering
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

  // Loads all scans from database and applies breed filter
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

  // Filters scans by selected breed
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

  // Deletes one scan and refreshes the list
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
              cacheExtent: 2500.0, // Turbo Mode: Pre-render 2-3 screens ahead
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
                            return HistoryCard(
                              item: item,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AnalysisResultScreen(
                                      detectedBreed: item.breedName,
                                      confidence: item.confidence,
                                      imagePath: item.imagePath,
                                      similarBreeds: item.similarBreeds,
                                      gatekeeperConfidence: item.gatekeeperConfidence,
                                      fromHistory: true,
                                      existingId: item.id,
                                      initialPersonality: item.personality,
                                    ),
                                  ),
                                );
                                refresh();
                              },
                              onDismissed: () => _deleteItem(item.id),
                            );
                          },
                          childCount: _filteredHistory.length,
                        ),
                      ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
    ));
  }
}
