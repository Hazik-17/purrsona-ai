import 'package:flutter/material.dart';
import '../models/breed.dart';
import '../services/json_data_service.dart';

/** Shows detailed info about one breed - history, traits, health, care */
class BreedInfoScreen extends StatefulWidget {
  final String breedName;

  const BreedInfoScreen({super.key, required this.breedName});

  @override
  State<BreedInfoScreen> createState() => _BreedInfoScreenState();
}

class _BreedInfoScreenState extends State<BreedInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Breed? _breed;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBreedInfo();
  }

  @override
  void didUpdateWidget(BreedInfoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.breedName != oldWidget.breedName) {
      _loadBreedInfo();
    }
  }

  // Loads breed details from the encyclopedia
  Future<void> _loadBreedInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final breed = JsonDataService().getBreedInfo(widget.breedName);
      setState(() {
        _breed = breed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getTemperamentColor(String trait) {
    final t = trait.toLowerCase().trim();
    if (t.contains('active') || t.contains('energy')) return Colors.orange;
    if (t.contains('intelligent') || t.contains('smart')) return Colors.indigo;
    if (t.contains('social') || t.contains('loyal')) return Colors.pinkAccent;
    return const Color(0xFFD4746B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_breed == null) {
      return const Center(child: Text('Breed not found.'));
    }

    final breed = _breed!;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 320.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFAF8F5),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                breed.name,
                style: TextStyle(
                  color: innerBoxIsScrolled ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: innerBoxIsScrolled
                      ? null
                      : const [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    breed.imagePath,
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFD4746B),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFE8A89B),
                tabs: const [
                  Tab(text: "Overview"),
                  Tab(text: "Health"),
                  Tab(text: "Lifestyle"),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(breed),
          _buildHealthTab(breed),
          _buildLifestyleTab(breed),
        ],
      ),
    );
  }

// --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(Breed breed) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Tagline
        Center(
          child: Text(
            '"${breed.tagline}"',
            style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Color(0xFFD4746B),
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        // Quick Stats Grid
        Row(
          children: [
            _buildStatCard(Icons.public, "Origin", breed.origin.split('/')[0]),
            const SizedBox(width: 12),
            _buildStatCard(
                Icons.monitor_weight_outlined, "Weight", breed.weight),
            const SizedBox(width: 12),
            _buildStatCard(Icons.cake_outlined, "Lifespan",
                breed.lifespan.replaceAll('years', 'yrs')),
          ],
        ),
        const SizedBox(height: 24),

        // Description
        const Text("About the Breed",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          breed.description,
          style: const TextStyle(
              fontSize: 15, height: 1.6, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 24),

        // Temperament Chips
        const Text("Personality",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: breed.temperament
              .map((t) => Chip(
                    label: Text(t,
                        style: TextStyle(
                            color: _getTemperamentColor(t),
                            fontWeight: FontWeight.bold)),
                    backgroundColor: _getTemperamentColor(t).withAlpha(25),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),

        // Fun Facts
        if (breed.funFacts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6B73FF).withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6B73FF).withAlpha(76)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Color(0xFF6B73FF)),
                    SizedBox(width: 8),
                    Text("Did You Know?",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B73FF))),
                  ],
                ),
                const SizedBox(height: 12),
                ...breed.funFacts.map((fact) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ",
                              style: TextStyle(
                                  color: Color(0xFF6B73FF),
                                  fontWeight: FontWeight.bold)),
                          Expanded(
                              child: Text(fact,
                                  style: const TextStyle(
                                      fontSize: 14, color: Color(0xFF444444)))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  // --- TAB 2: HEALTH ---
  Widget _buildHealthTab(Breed breed) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionCard(
          title: "General Health",
          icon: Icons.favorite,
          color: Colors.redAccent,
          content:
              Text(breed.healthSummary, style: const TextStyle(height: 1.5)),
        ),
        const SizedBox(height: 20),
        const Text("Potential Genetic Risks",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Consult your vet about these specific conditions:",
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        ...breed.geneticIssues.map((issue) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)
                ],
                border: Border.all(color: Colors.redAccent.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Text(issue,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            )),
      ],
    );
  }

  // --- TAB 3: LIFESTYLE (CARE) ---
  Widget _buildLifestyleTab(Breed breed) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionCard(
          title: "Grooming Needs",
          icon: Icons.content_cut,
          color: const Color(0xFFE8A89B),
          content: Text(breed.grooming, style: const TextStyle(height: 1.5)),
        ),
        const SizedBox(height: 20),
        const Text("Expert Care Tips",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...breed.careTips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.green),
                    child:
                        const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(tip,
                          style: const TextStyle(fontSize: 15, height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFD4746B), size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required Color color,
      required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51)),
        boxShadow: [BoxShadow(color: color.withAlpha(12), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const Divider(height: 24),
          content,
        ],
      ),
    );
  }
}

// Helper for the Sliver Persistent Header to keep tabs visible
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFAF8F5),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
