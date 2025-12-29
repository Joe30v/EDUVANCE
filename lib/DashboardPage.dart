import 'dart:ui'; // Required for Glass Blur
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  final User user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isMenuExpanded = false;
  int _selectedIndex = 0;
  final LayerLink _menuLayerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    // 1. NAME FIX: Use displayName only. If null, use "User". NEVER use email.
    final String displayName = (widget.user.displayName != null && widget.user.displayName!.isNotEmpty) 
        ? widget.user.displayName! 
        : "User"; 

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // --- 1. PREMIUM GRADIENT BACKGROUND ---
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC4D7F5), // Soft Apple Blue
                  Color(0xFFE8EBF2), // Muted Grey-White
                  Color(0xFFF2F4F8), // Pure White
                ],
              ),
            ),
          ),

          // --- 2. MAIN LAYOUT (Column) ---
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Header
                  _buildHeader(displayName),
                  
                  const SizedBox(height: 20),
                  
                  // --- TASK CONTAINER (EXPANDED) ---
                  // Stretches to fill space between Header and Reward Card
                  Expanded(
                    child: _buildGlassTaskSection(),
                  ),

                  const SizedBox(height: 20),
                  
                  // --- REWARD CARD (Fixed above bottom nav) ---
                  _buildGlassRewardContainer(),
                  
                  // Spacer to lift everything above the floating nav
                  const SizedBox(height: 110), 
                ],
              ),
            ),
          ),

          // --- 3. FLOATING BOTTOM NAV (Glass) ---
          Positioned(
            left: 0, 
            right: 0,
            bottom: 40,
            child: Center(child: _buildGlassFloatingBottomNav()),
          ),
          
          // --- 4. POPUP MENU (Glass) ---
          if (_isMenuExpanded)
            Positioned(
              width: 60, 
              child: CompositedTransformFollower(
                link: _menuLayerLink,
                showWhenUnlinked: false,
                offset: const Offset(-10, 50), 
                child: _buildGlassExpandedMenu(),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  //            APPLE GLASS HELPERS
  // ==========================================

  Widget _buildGlassContainer({required Widget child, required double borderRadius}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        // Stronger Blur for "Liquid" feel
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), 
        child: Container(
          decoration: BoxDecoration(
            // High transparency (0.4) for that "Liquid Glass" look
            color: Colors.white.withOpacity(0.40), 
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.6), // Subtle icy border
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Very soft shadow
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ==========================================
  //               WIDGETS
  // ==========================================

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile + Name
        Expanded(
          child: GestureDetector(
            onTap: () => print("Profile Clicked"),
            child: Row(
              children: [
                // Solid Profile (Not Glass, as requested)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent, 
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_outline, size: 26, color: Colors.black),
                ),
                const SizedBox(width: 15),
                
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.unfold_more, size: 18, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Menu Button (Semi-Glass)
        CompositedTransformTarget(
          link: _menuLayerLink,
          child: GestureDetector(
            onTap: () => setState(() => _isMenuExpanded = !_isMenuExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.more_horiz, color: Colors.black, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassExpandedMenu() {
    return _buildGlassContainer(
      borderRadius: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuIcon(Icons.mail_outline, () => print("Mail")),
            const SizedBox(height: 25),
            _buildMenuIcon(Icons.nightlight_round, () => print("Dark Mode")),
            const SizedBox(height: 25),
            _buildMenuIcon(Icons.event_available_outlined, () => print("Add")),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 26, color: Colors.black87),
    );
  }

  // --- LIQUID GLASS TASK CONTAINER ---
  Widget _buildGlassTaskSection() {
    return _buildGlassContainer(
      borderRadius: 35,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('uid', isEqualTo: widget.user.uid)
            .orderBy('dueDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading tasks"));
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data?.docs ?? [];
          final now = DateTime.now();
          
          final todayTasks = tasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['dueDate'] == null) return false;
            DateTime date = (data['dueDate'] as Timestamp).toDate();
            return date.year == now.year && date.month == now.month && date.day == now.day;
          }).toList();

          final upcomingTasks = tasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['dueDate'] == null) return false;
            DateTime date = (data['dueDate'] as Timestamp).toDate();
            return date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
          }).toList();

          // Internal scrolling for tasks
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionPill("Today"),
                const SizedBox(height: 15),
                if (todayTasks.isEmpty)
                   Padding(
                     padding: const EdgeInsets.only(left: 5, bottom: 20),
                     child: Text("No tasks for today", style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 15)),
                   )
                else
                  ...todayTasks.map((doc) => _buildCleanTaskItem(doc, isToday: true)),
                  
                const SizedBox(height: 20),

                _buildSectionPill("Upcoming"),
                const SizedBox(height: 15),
                if (upcomingTasks.isEmpty)
                   Padding(
                     padding: const EdgeInsets.only(left: 5),
                     child: Text("No upcoming tasks", style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 15)),
                   )
                else
                  ...upcomingTasks.map((doc) => _buildCleanTaskItem(doc, isToday: false)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6), // Slightly frostier than bg
        border: Border.all(color: Colors.black, width: 1.5), 
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 22, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildCleanTaskItem(QueryDocumentSnapshot doc, {required bool isToday}) {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime date = (data['dueDate'] as Timestamp).toDate();
    final String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] ?? 'Untitled',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87), 
          ),
          const SizedBox(height: 4),
          Text(
            isToday ? "Due: (Today)" : "Due: ($formattedDate)",
            style: TextStyle(
              fontSize: 13, 
              color: Colors.black.withOpacity(0.5), 
              fontWeight: FontWeight.w700
            ),
          ),
        ],
      ),
    );
  }

  // --- LIQUID GLASS REWARD CONTAINER ---
  Widget _buildGlassRewardContainer() {
    return _buildGlassContainer(
      borderRadius: 40,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              height: 60, width: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, 
                color: Color(0xFFCD7F32), 
              ),
              child: const Center(child: Icon(Icons.star, color: Colors.white, size: 30)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Level 1", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const SizedBox(height: 5),
                  Text(
                    "Congratulations!\nYou've earned the Bronze Taskmaster Badge!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.6)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- LIQUID GLASS BOTTOM NAV ---
  Widget _buildGlassFloatingBottomNav() {
    // Constrained width to look like a floating island
    return Container(
      constraints: const BoxConstraints(maxWidth: 340), 
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildGlassContainer(
        borderRadius: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
            children: [
              _buildNavIcon(Icons.home_filled, 0),
              _buildNavIcon(Icons.search, 1),
              _buildNavIcon(Icons.assignment_outlined, 2), 
              _buildNavIcon(Icons.calendar_today_rounded, 3), 
              _buildNavIcon(Icons.trending_up, 4), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.transparent,
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? Colors.black : Colors.black54,
        ),
      ),
    );
  }
}