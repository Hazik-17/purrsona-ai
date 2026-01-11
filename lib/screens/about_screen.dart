import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/about_controller.dart';
import '../models/about_data.dart';
import '../services/performance_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final AboutController _controller = AboutController();
  late Future<AboutData> _aboutDataFuture;

  @override
  void initState() {
    super.initState();
    _aboutDataFuture = _controller.loadAppInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D3D3D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "About",
          style: TextStyle(color: Color(0xFF3D3D3D), fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<AboutData>(
        future: _aboutDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Failed to load app info"));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Header: App Logo + Name + Version
                _buildHeader(data),
                const SizedBox(height: 32),
                // Project Background
                _buildProjectBackground(data),
                const SizedBox(height: 24),
                // System Architecture
                _buildSystemArchitecture(data),
                const SizedBox(height: 24),
                // Model Development Pipeline
                _buildModelDevelopmentPipeline(data),
                const SizedBox(height: 24),
                // Key Findings
                _buildKeyFindings(data),
                const SizedBox(height: 24),
                // Developer Profile
                _buildDeveloperProfile(),
                const SizedBox(height: 24),
                // Technical Specifications
                _buildTechnicalSpecs(data),
                const SizedBox(height: 24),
                // Developer Options
                _buildDeveloperOptions(),
                const SizedBox(height: 32),
                // Footer
                _buildFooter(),
              ],
            );
          } else {
            return const Center(child: Text("No data available"));
          }
        },
      ),
    );
  }

  Widget _buildHeader(AboutData data) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4746B).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/icon/me.jpg'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          data.appName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D3D3D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Version ${data.appVersion} (${data.buildNumber})",
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF7B7B7B),
          ),
        ),
      ],
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildProjectBackground(AboutData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Why Purrsona AI?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Manual identification of cat breeds is prone to human error, particularly with visually similar breeds like the Birman and Ragdoll. Additionally, existing tools often rely on cloud connectivity, limiting their use in remote areas.",
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSystemArchitecture(AboutData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          "System Architecture",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D3D3D),
          ),
        ),
        leading: const Icon(Icons.architecture, color: Color(0xFFD4746B)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepIcon(Icons.filter_alt, "Gatekeeper"),
                    const Icon(Icons.arrow_forward, color: Color(0xFF7B7B7B)),
                    _buildStepIcon(Icons.search, "Generalist"),
                    const Icon(Icons.arrow_forward, color: Color(0xFF7B7B7B)),
                    _buildStepIcon(Icons.verified, "Expert"),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "This system implements a Hierarchical Deep Learning Pipeline.\n\nIt processes images through three stages:\n1. Gatekeeper (filters non-cats)\n2. Generalist (classifies 12 primary breeds)\n3. Expert (resolves fine-grained ambiguities).",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStepIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8A89B).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFD4746B), size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }

  Widget _buildModelDevelopmentPipeline(AboutData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Model Development Pipeline",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
            const SizedBox(height: 16),
            ...data.modelPipeline.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              return Column(
                children: [
                  if (index > 0) ...[
                    Container(
                      width: 2,
                      height: 20,
                      color: const Color(0xFFD4746B).withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A89B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(stage.icon, color: const Color(0xFFD4746B), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D3D3D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stage.description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildKeyFindings(AboutData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Key Findings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.0,
              ),
              itemCount: data.detailedFindings.length,
              itemBuilder: (context, index) {
                final entry = data.detailedFindings.entries.elementAt(index);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D3D3D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7B7B7B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDeveloperProfile() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Developer Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Name: Mohamad Hazik Haikal Bin Razak\nStudent ID: 2024779495",
              style: TextStyle(fontSize: 16, color: Color(0xFF3D3D3D)),
            ),
            SizedBox(height: 8),
            Text(
              "Supervisor: Mr. Azizian Mohd Sapawi\nBachelor of Computer Science (Hons)\nFaculty of Computer and Mathematical Sciences\nUniversiti Teknologi MARA (UiTM) Shah Alam",
              style: TextStyle(fontSize: 16, color: Color(0xFF3D3D3D)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTechnicalSpecs(AboutData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Technical Specifications",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecRow("Flutter SDK", data.flutterVersion),
            _buildSpecRow("TFLite Runtime", data.tfliteVersion),
            _buildSpecRow("Model Architecture", data.databaseVersion),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSpecRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3D3D3D),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7B7B7B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperOptions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ValueListenableBuilder<bool>(
        valueListenable: PerformanceService.instance.isOverlayVisible,
        builder: (context, isVisible, child) {
          return SwitchListTile(
            title: const Text(
              "Show Performance Overlay",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3D3D3D),
              ),
            ),
            subtitle: const Text(
              "Monitor RAM usage globally",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7B7B7B),
              ),
            ),
            value: isVisible,
            onChanged: (value) {
              PerformanceService.instance.toggleOverlay(value);
            },
            activeThumbColor: const Color(0xFFD4746B),
          );
        },
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFooter() {
    return const Text(
      "Developed for CSP650 - UiTM",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF7B7B7B),
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
