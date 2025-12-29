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

  @override
  Widget build(BuildContext context) {
    // Extract display name or use email username
    final String displayName = widget.user.displayName ?? 
                               widget.user.email!.split('@')[0];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          // MAIN CONTENT
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(displayName),
                  const SizedBox(height: 30),
                  
                  // TASKS STREAM
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tasks')
                        .where('uid', isEqualTo: widget.user.uid) // Filter by user
                        .orderBy('dueDate')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final tasks = snapshot.data?.docs ?? [];
                      
                      if (tasks.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("No tasks found. Add one in Firestore!"),
                          ),
                        );
                      }

                      final now = DateTime.now();
                      final todayTasks = tasks.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['dueDate'] == null) return false;
                        DateTime date = (data['dueDate'] as Timestamp).toDate();
                        return date.year == now.year && 
                               date.month == now.month && 
                               date.day == now.day;
                      }).toList();

                      final upcomingTasks = tasks.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['dueDate'] == null) return false;
                        DateTime date = (data['dueDate'] as Timestamp).toDate();
                        return date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
                      }).toList();

                      return Column(
                        children: [
                          if (todayTasks.isNotEmpty) ...[
                            _buildSectionHeader("Today"),
                            ...todayTasks.map((doc) => _buildTaskCard(doc)),
                            const SizedBox(height: 20),
                          ],
                          if (upcomingTasks.isNotEmpty) ...[
                            _buildSectionHeader("Upcoming"),
                            ...upcomingTasks.map((doc) => _buildTaskCard(doc)),
                          ]
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  _buildGamificationCard(),
                ],
              ),
            ),
          ),

          // FLOATING BOTTOM NAV
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.person_outline, size: 30),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.user.email ?? "",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        
        // Expanding Menu
        GestureDetector(
          onTap: () {
            setState(() {
              _isMenuExpanded = !_isMenuExpanded;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 50,
            height: _isMenuExpanded ? 150 : 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_isMenuExpanded) ...[
                  // Logout Button
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20, color: Colors.red),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    tooltip: "Logout",
                  ),
                  const Icon(Icons.nightlight_round, size: 20),
                ] else 
                  const Icon(Icons.more_horiz),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, top: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime date = (data['dueDate'] as Timestamp).toDate();
    final String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] ?? 'Untitled',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            "Due: $formattedDate",
            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.brown),
            child: const Center(child: Icon(Icons.star, color: Colors.white)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Level 1", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text(
                  "Congratulations! You've earned the Bronze Taskmaster Badge!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.home_filled, size: 28), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search, size: 28), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add_circle, size: 40, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.calendar_today_outlined, size: 28), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline, size: 28), onPressed: () {}),
        ],
      ),
    );
  }
}