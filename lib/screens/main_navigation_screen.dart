import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'welcome_screen.dart';
import 'codex_screen.dart';
import 'nearby_services_screen.dart';
import 'archives_screen.dart';

final GlobalKey<WelcomeScreenState> homeKey = GlobalKey();
final GlobalKey<ArchivesScreenState> historyKey = GlobalKey();

/// Bottom navigation bar with Home, Codex, Vet Services, and History tabs
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // The Screens
  final List<Widget> _screens = [
    WelcomeScreen(key: homeKey),
    const CodexScreen(),
    const VetClinicScreen(),
    ArchivesScreen(key: historyKey),
  ];

  // Public method to switch tabs programmatically
  void switchToTab(int index) {
    _handleTabChange(index);
  }

  // Changes the tab and refreshes data when needed
  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Smart Refresh Logic
    if (index == 0) homeKey.currentState?.refreshRecents();
    if (index == 3) historyKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Soft cream background
      // 3. STUNNING UI: Extend body behind nav bar (optional, keeps it clean)
      extendBody: true,

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // 4. CUSTOM FLOATING NAV BAR
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // Float above bottom
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35), // Pill shape
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8A89B).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10), // Soft drop shadow
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.center_focus_weak_rounded, Icons.center_focus_strong_rounded, "Scan"),
            _buildNavItem(1, Icons.menu_book_rounded, Icons.menu_book_rounded, "Codex"),
            _buildNavItem(2, Icons.place_outlined, Icons.place_outlined, "Place"),
            _buildNavItem(3, Icons.history_rounded, Icons.history_edu_rounded, "History"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOff, IconData iconOn, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _handleTabChange(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4746B).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            Icon(
              isSelected ? iconOn : iconOff,
              color: isSelected ? const Color(0xFFD4746B) : Colors.grey[400],
              size: 24,
            )
                .animate(target: isSelected ? 1 : 0) // Trigger animation on selection
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 200.ms)
                .then()
                .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 100.ms),

            // Animated Label (Only visible when selected)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: isSelected ? null : 0, // Collapse width when not selected
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFD4746B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}