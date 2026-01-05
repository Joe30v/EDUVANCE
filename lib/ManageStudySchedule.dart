import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// --- DATA MODELS ---

enum TaskPriority { High, Medium, Low }

// --- SCREEN 1: STUDY SCHEDULE PLANNER (Main Page) ---

class StudySchedulePlanner extends StatefulWidget {
  const StudySchedulePlanner({super.key});

  @override
  State<StudySchedulePlanner> createState() => _StudySchedulePlannerState();
}

class _StudySchedulePlannerState extends State<StudySchedulePlanner> {
  String _selectedTab = "Today";
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- SHOW CUSTOM SUCCESS DIALOG ---
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // OPTIMIZATION: Auto-close faster (1.5s) for a snappier feel
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 2.5),
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Task saved successfully",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Study Schedule Planner",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTabButton("Today"),
                _buildTabButton("Upcoming"),
                _buildTabButton("Completed"),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('uid', isEqualTo: currentUser?.uid)
                  .orderBy('deadline')
                  .snapshots(),
              builder: (context, snapshot) {
                // OPTIMIZATION 1: Instant Load
                // If we have data (even from cache), show it immediately.
                // We only show the spinner if we have absolutely NO data.
                if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error. Check console for Index link.",
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No tasks found", style: TextStyle(color: Colors.grey.shade500)),
                  );
                }

                final tasks = snapshot.data!.docs;
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final todayEnd = todayStart.add(const Duration(days: 1));

                final filteredTasks = tasks.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['deadline'] == null) return false;

                  final date = (data['deadline'] as Timestamp).toDate();
                  final isCompleted = data['isCompleted'] ?? false;

                  if (_selectedTab == "Completed") return isCompleted;
                  if (isCompleted) return false;

                  if (_selectedTab == "Today") {
                    return date.isAfter(todayStart) && date.isBefore(todayEnd);
                  } else if (_selectedTab == "Upcoming") {
                    return date.isAfter(todayEnd);
                  }
                  return true;
                }).toList();

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Text(
                      "No ${_selectedTab.toLowerCase()} tasks",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return TaskCard(doc: filteredTasks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddNewTaskScreen()),
          );

          if (result == true && context.mounted) {
            _showSuccessDialog();
          }
        },
        label: const Text("Add Task"),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text) {
    final isSelected = _selectedTab == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// --- WIDGET: TASK CARD ---

class TaskCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const TaskCard({super.key, required this.doc});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isExpanded = false;

  void _handleTaskCompletion(bool currentStatus) {
    // OPTIMIZATION 2: Removed 'await'. 
    // This updates the local UI immediately via the Stream.
    FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.doc.id)
        .update({'isCompleted': !currentStatus});
  }

  void _deleteTask() {
    // OPTIMIZATION 3: Removed 'await'. 
    // Delete happens instantly in UI, syncs in background.
    FirebaseFirestore.instance.collection('tasks').doc(widget.doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? '';
    final DateTime date = (data['deadline'] as Timestamp).toDate();
    final bool isCompleted = data['isCompleted'] ?? false;
    final bool isLongTitle = title.length > 20;
    final String displayTitle = (_isExpanded || !isLongTitle)
        ? title
        : "${title.substring(0, 20)}...";

    return Container(
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
              onChanged: (_) => _handleTaskCompletion(isCompleted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                const SizedBox(height: 4),
                Text(
                  "Due: (${DateFormat('dd/MM/yyyy').format(date)})",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            onSelected: (value) {
              if (value == 'remove') _deleteTask();
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
    );
  }
}

// --- SCREEN 2: ADD NEW TASK ---

class AddNewTaskScreen extends StatefulWidget {
  const AddNewTaskScreen({super.key});

  @override
  State<AddNewTaskScreen> createState() => _AddNewTaskScreenState();
}

class _AddNewTaskScreenState extends State<AddNewTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskPriority? _selectedPriority;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  // Note: Removed _isSaving loading state because saving is now instant

  bool _showTitleError = false;
  bool _showDateError = false;
  bool _showPriorityError = false;

  void _saveTask() {
    setState(() {
      _showTitleError = _titleController.text.isEmpty;
      _showDateError = _selectedDate == null || _selectedTime == null;
      _showPriorityError = _selectedPriority == null;
    });

    if (!_showTitleError && !_showDateError && !_showPriorityError) {
      final finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // OPTIMIZATION 4: "Fire and Forget"
      // We removed 'await' here.
      FirebaseFirestore.instance.collection('tasks').add({
        'uid': currentUser?.uid,
        'title': _titleController.text,
        'deadline': Timestamp.fromDate(finalDateTime),
        'priority': _selectedPriority.toString().split('.').last,
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((error) {
         // Log error silently since user has already left the screen
         debugPrint("Error saving in background: $error");
      });

      // Close the screen IMMEDIATELY
      Navigator.pop(context, true); 
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add New Task",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Task Name"),
            TextField(
              controller: _titleController,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: "Enter Task Name (Max 20 chars)",
                counterText: "",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: _showTitleError ? Colors.red : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: _showTitleError ? Colors.red : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
            if (_showTitleError) _buildErrorText("Task Name is Required"),

            const SizedBox(height: 24),

            _buildLabel("Deadline"),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _showDateError ? Colors.red : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          _selectedDate == null
                              ? "DD/MM/YYYY"
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? (_showDateError ? Colors.red : Colors.grey.shade400)
                                : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _showDateError ? Colors.red : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          _selectedTime == null
                              ? "Time"
                              : _selectedTime!.format(context),
                          style: TextStyle(
                            color: _selectedTime == null
                                ? (_showDateError ? Colors.red : Colors.grey.shade400)
                                : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_showDateError) _buildErrorText("DD/MM/YY Time is Required"),

            const SizedBox(height: 24),

            _buildLabel("Priority"),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildPriorityRadio("High", TaskPriority.High),
                const SizedBox(width: 16),
                _buildPriorityRadio("Medium", TaskPriority.Medium),
                const SizedBox(width: 16),
                _buildPriorityRadio("Low", TaskPriority.Low),
              ],
            ),
            if (_showPriorityError) _buildErrorText("Priority Selection is Required"),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                // Removed spinner, just showing text for instant feel
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildErrorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0, left: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityRadio(String label, TaskPriority val) {
    final isSelected = _selectedPriority == val;
    final isError = _showPriorityError && _selectedPriority == null;

    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = val),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isError ? Colors.red : Colors.grey, width: 2),
            ),
            padding: const EdgeInsets.all(3),
            child: isSelected
                ? Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}