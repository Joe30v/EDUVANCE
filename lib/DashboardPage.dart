import 'dart:ui'; // Required for Glass Blur
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ManageStudySchedule.dart'; 

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
  
  String _displayName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (widget.user.displayName != null && widget.user.displayName!.isNotEmpty) {
      _displayName = widget.user.displayName!;
    }

    try {
      await widget.user.reload();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (mounted && currentUser?.displayName != null) {
        setState(() {
          _displayName = currentUser!.displayName!;
        });
      }
    } catch (e) {
      debugPrint("Error loading user name: $e");
    }
  }

  // --- UPDATED: SHOW ALL TASKS (LEFT SIDE DRAWER) ---
  void _showAllTasksSheet(String title, List<QueryDocumentSnapshot> allTasks) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Tap outside to close
      barrierLabel: "Close",
      barrierColor: Colors.black54, // Dimmed background
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft, // Anchor to Left
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.80, // 80% Width
              height: double.infinity, // Full Height
              decoration: const BoxDecoration(
                color: Colors.white,
                // Round only the right corners
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50), // Added top padding for Safe Area
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allTasks.length,
                      itemBuilder: (context, index) {
                        return DashboardTaskCard(doc: allTasks[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Animation: Slide from Left (-1) to Right (0)
        final tween = Tween(begin: const Offset(-1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false, 
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(_displayName),
                  const SizedBox(height: 25),
                  // --- TASK SECTION ---
                  Expanded(
                    child: _buildLiquidGlassTaskSection(),
                  ),
                  const SizedBox(height: 20),
                  _buildLiquidGlassRewardContainer(),
                  const SizedBox(height: 130), 
                ],
              ),
            ),
          ),
          Positioned(
            left: 0, 
            right: 0,
            bottom: 40,
            child: Center(child: _buildLiquidGlassFloatingBottomNav()),
          ),
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

  Widget _buildLiquidGlassContainer({
    required Widget child, 
    required double borderRadius,
    double width = double.infinity 
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6F8).withOpacity(0.85), 
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white, 
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), 
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => print("Profile Clicked"),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    border: Border.all(color: Colors.black, width: 2), 
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_outline, size: 26, color: Colors.black),
                ),
                const SizedBox(width: 15),
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
        CompositedTransformTarget(
          link: _menuLayerLink,
          child: GestureDetector(
            onTap: () => setState(() => _isMenuExpanded = !_isMenuExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F8), 
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
    return _buildLiquidGlassContainer(
      borderRadius: 30,
      width: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuIcon(Icons.mail_outline, () => print("Mail")),
            const SizedBox(height: 25),
            _buildMenuIcon(Icons.nightlight_round, () => print("Do not disturb")),
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

  // --- UPDATED TASK SECTION LOGIC ---
  Widget _buildLiquidGlassTaskSection() {
    return _buildLiquidGlassContainer(
      borderRadius: 35,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('uid', isEqualTo: widget.user.uid)
            .orderBy('deadline') 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading tasks"));
          
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(
               child: CircularProgressIndicator(color: Colors.black),
             );
          }

          final tasks = snapshot.data?.docs ?? [];
          final now = DateTime.now();
          
          // Filter Tasks
          final todayTasks = tasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['deadline'] == null) return false;
            DateTime date = (data['deadline'] as Timestamp).toDate();
            return !data['isCompleted'] && date.year == now.year && date.month == now.month && date.day == now.day;
          }).toList();

          final upcomingTasks = tasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['deadline'] == null) return false;
            DateTime date = (data['deadline'] as Timestamp).toDate();
            return !data['isCompleted'] && date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
          }).toList();

          // --- LIMIT LOGIC UPDATED ---
          
          // 1. Today: Show max 2 (As requested)
          final visibleTodayTasks = todayTasks.take(2).toList();
          final bool canExpandToday = todayTasks.length > 2;

          // 2. Upcoming: Show max 1 (As requested)
          final visibleUpcomingTasks = upcomingTasks.take(1).toList();
          final bool canExpandUpcoming = upcomingTasks.length > 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TODAY SECTION ---
                _buildSectionPill(
                  "Today", 
                  canExpandToday, 
                  () => _showAllTasksSheet("Today's Tasks", todayTasks)
                ),
                const SizedBox(height: 15),
                if (visibleTodayTasks.isEmpty)
                   Padding(
                     padding: const EdgeInsets.only(left: 5, bottom: 20),
                     child: Text("No tasks for today", style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 15)),
                   )
                else
                  ...visibleTodayTasks.map((doc) => DashboardTaskCard(doc: doc)),
                  
                const SizedBox(height: 20),

                // --- UPCOMING SECTION ---
                _buildSectionPill(
                  "Upcoming", 
                  canExpandUpcoming, 
                  () => _showAllTasksSheet("Upcoming Tasks", upcomingTasks)
                ),
                const SizedBox(height: 15),
                if (visibleUpcomingTasks.isEmpty)
                   Padding(
                     padding: const EdgeInsets.only(left: 5),
                     child: Text("No upcoming tasks", style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 15)),
                   )
                else
                  ...visibleUpcomingTasks.map((doc) => DashboardTaskCard(doc: doc)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Updated to accept Tap and Expansion State
  Widget _buildSectionPill(String title, bool canExpand, VoidCallback onExpand) {
    return GestureDetector(
      onTap: canExpand ? onExpand : null, // Only clickable if expandable
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: canExpand ? Colors.black : Colors.white, // Visual feedback: Black if clickable
          border: Border.all(color: Colors.black, width: 1.5), 
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title, 
              style: TextStyle(
                fontWeight: FontWeight.w800, 
                fontSize: 16,
                color: canExpand ? Colors.white : Colors.black
              )
            ),
            const SizedBox(width: 8),
            // Rotate the arrow to point right if it opens a side drawer? 
            // Keeping it simple per request, but a right chevron > might make more sense now.
            Icon(
              Icons.keyboard_arrow_down, 
              size: 22, 
              color: canExpand ? Colors.white : Colors.black
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidGlassRewardContainer() {
    return _buildLiquidGlassContainer(
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

  Widget _buildLiquidGlassFloatingBottomNav() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340), 
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildLiquidGlassContainer(
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
      onTap: () {
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudySchedulePlanner()),
          );
        } else {
          setState(() => _selectedIndex = index);
        }
      },
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

// ==========================================
//    DASHBOARD TASK CARD
// ==========================================

class DashboardTaskCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const DashboardTaskCard({super.key, required this.doc});

  @override
  State<DashboardTaskCard> createState() => _DashboardTaskCardState();
}

class _DashboardTaskCardState extends State<DashboardTaskCard> {
  bool _isExpanded = false;

  Future<void> _toggleTaskCompletion(bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.doc.id)
        .update({'isCompleted': !currentStatus});
  }

  Future<void> _deleteTask() async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.doc.id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? '';
    final DateTime date = (data['deadline'] as Timestamp).toDate();
    final String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final bool isCompleted = data['isCompleted'] ?? false;
    
    final bool isLongTitle = title.length > 20;
    final String displayTitle = (_isExpanded || !isLongTitle) 
        ? title 
        : "${title.substring(0, 20)}...";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: isCompleted,
              activeColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (_) => _toggleTaskCompletion(isCompleted),
            ),
          ),
          const SizedBox(width: 8),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? Colors.grey : Colors.black
                              ),
                            ),
                          ),
                          if (isLongTitle)
                            InkWell(
                              onTap: () => setState(() => _isExpanded = !_isExpanded),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'remove') {
                          _deleteTask();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Remove task', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Due: ($formattedDate)",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}