import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/breed.dart';
import '../services/json_data_service.dart';
import 'breed_info_screen.dart';

class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Breed> _allBreeds = [];
  List<Breed> _filteredBreeds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBreeds() async {
    // Simulate a short delay for smoother UI feel or actual async loading
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      // Defer the state update until after the current frame is built to avoid scheduling a build during a build.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Re-check if mounted as the callback is asynchronous
          final service = JsonDataService();
          setState(() {
            _allBreeds = service.getAllBreeds();
            _filteredBreeds = _allBreeds;
            _isLoading = false;
          });
        }
      });
    }
  }

  void _filterBreeds(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBreeds = _allBreeds;
      } else {
        _filteredBreeds = _allBreeds.where((breed) {
          final name = breed.name.toLowerCase();
          final origin = breed.origin.toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || origin.contains(searchLower);
        }).toList();
      }
    });
  }

  // Helper for colorful chips
  Color _getTemperamentColor(String trait) {
    final t = trait.toLowerCase().trim();
    if (t.contains('active') || t.contains('high energy')) return Colors.orange;
    if (t.contains('intelligent') || t.contains('smart')) return Colors.indigo;
    if (t.contains('loyal') || t.contains('social') || t.contains('velcro')) {
      return Colors.pinkAccent;
    }
    if (t.contains('calm') || t.contains('gentle')) return Colors.teal;
    if (t.contains('shy') || t.contains('quiet')) return Colors.blueGrey;
    return const Color(0xFFD4746B); // Default Coral
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Cat Breed Codex',
          style: TextStyle(
            color: Color(0xFF3D3D3D),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8A89B).withAlpha(38), // 0.15 opacity
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterBreeds,
                decoration: InputDecoration(
                  hintText: 'Search for a breed...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFFE8A89B)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // Breed List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8A89B)))
                : _filteredBreeds.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        itemCount: _filteredBreeds.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildBreedCard(_filteredBreeds[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No breeds found',
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBreedCard(Breed breed) {
    List<String> traits = breed.temperament.take(3).toList();
    String breedName = breed.name;
    String tagline = breed.tagline;
    String imagePath = breed.imagePath;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BreedInfoScreen(breedName: breed.id),
          ),
        );
      },
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10), // 0.04 opacity
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Thumbnail
            Hero(
              tag: 'breed_image_${breed.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 140,
                  height: 150,
                  // Check if path exists. If null, show Icon immediately.
                  child: imagePath.isNotEmpty
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          cacheWidth: 400, // Limit memory usage for assets
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.pets, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.pets, color: Colors.grey),
                        ),
                ),
              ),
            ),

            // Info Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      breedName,
                      style: const TextStyle(
                        color: Color(0xFF3D3D3D),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tagline,
                      style: const TextStyle(
                        color: Color(0xFFE8A89B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Colorful Trait Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: traits.map((trait) {
                        final color = _getTemperamentColor(trait);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20), // 0.08 opacity
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trait.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow Icon
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFE8A89B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
