import 'dart:io';
import 'package:flutter/material.dart';
import '../models/prediction.dart';
import '../services/database_helper.dart';
import 'prediction_result_screen.dart';
import '../widgets/history_chart_widget.dart';

/// Shows all past scans with chart and filtering
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Prediction> _allPredictions = [];
  List<Prediction> _filteredPredictions = [];
  bool _isLoading = true;
  String? _selectedBreedFilter;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Loads all past scans from database
  Future<void> _loadHistory() async {
    final db = DatabaseHelper();
    final data = await db.getHistory();

    if (mounted) {
      setState(() {
        _allPredictions = data;
        _isLoading = false;
        if (_selectedBreedFilter != null) {
          _filteredPredictions = _allPredictions
              .where((p) => p.breedName == _selectedBreedFilter)
              .toList();
        } else {
          _filteredPredictions = _allPredictions;
        }
      });
    }
  }

  // Filters the list when user picks a breed
  void _onBreedSelected(String? breed) {
    setState(() {
      _selectedBreedFilter = breed;
      if (breed == null) {
        _filteredPredictions = _allPredictions;
      } else {
        _filteredPredictions =
            _allPredictions.where((p) => p.breedName == breed).toList();
      }
    });
  }

  Future<void> _deletePrediction(String id) async {
    await DatabaseHelper().deletePrediction(id);
    await _loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prediction deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteDialog(Prediction prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prediction'),
        content: const Text('Are you sure you want to delete this result?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePrediction(prediction.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D3D3D)),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3D3D3D)),
      ),
      // CHANGE: Wrap CustomScrollView in RefreshIndicator
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8A89B)))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: const Color(0xFFE8A89B),
              child: CustomScrollView(
                cacheExtent: 2500.0, // Turbo Mode: Pre-render 2-3 screens ahead
                slivers: [
                  // CHART WIDGET (Scrollable)
                  if (_allPredictions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: DetectionInsightsWidget(
                        fullHistory: _allPredictions,
                        selectedBreed: _selectedBreedFilter,
                        onBreedSelected: _onBreedSelected,
                      ),
                    ),

                  // LIST HEADER
                  if (_allPredictions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: Row(
                          children: [
                            Text(
                              _selectedBreedFilter != null
                                  ? "Showing $_selectedBreedFilter"
                                  : "Recent Scans",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // THE LIST
                  _filteredPredictions.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final prediction = _filteredPredictions[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildPredictionCard(prediction),
                              );
                            },
                            childCount: _filteredPredictions.length,
                          ),
                        ),

                  // Bottom Padding
                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _allPredictions.isEmpty
                ? 'No Predictions Yet'
                : 'No $_selectedBreedFilter Found',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Prediction prediction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PredictionResultScreen(prediction: prediction),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: Image.file(
                    File(prediction.imagePath),
                    fit: BoxFit.cover,
                    cacheWidth: 800, // Increased for sharper quality in Turbo Mode
                    errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.breedName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(prediction.confidence * 100).toInt()}% Confidence',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                onPressed: () => _showDeleteDialog(prediction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
