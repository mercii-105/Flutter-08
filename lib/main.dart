import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'database_helper.dart';
import 'firebase_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const StudentDatabaseApp());
}

class StudentDatabaseApp extends StatelessWidget {
  const StudentDatabaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Database Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7661A8)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F4FC),
      ),
      home: const DatabaseHomePage(),
    );
  }
}

class DatabaseHomePage extends StatelessWidget {
  const DatabaseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Student Database',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFEAE3F7),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.storage), text: 'Local SQLite'),
              Tab(icon: Icon(Icons.cloud_outlined), text: 'Cloud Firestore'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [SQLiteStudentsPage(), CloudStudentsPage()],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// PART A: SQLITE LOCAL DATABASE
// --------------------------------------------------

class SQLiteStudentsPage extends StatefulWidget {
  const SQLiteStudentsPage({super.key});

  @override
  State<SQLiteStudentsPage> createState() => _SQLiteStudentsPageState();
}

class _SQLiteStudentsPageState extends State<SQLiteStudentsPage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  String searchQuery = '';

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    try {
      final data = await DatabaseHelper.instance.getStudents();

      if (!mounted) return;

      setState(() {
        students = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredStudents {
    return students.where((student) {
      final name = student['name'].toString().toLowerCase();
      final course = student['course'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      return name.contains(query) || course.contains(query);
    }).toList();
  }

  Future<void> showStudentDialog({Map<String, dynamic>? student}) async {
    final nameController = TextEditingController(
      text: student == null ? '' : student['name'],
    );

    final courseController = TextEditingController(
      text: student == null ? '' : student['course'],
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(student == null ? 'Add Student' : 'Edit Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final course = courseController.text.trim();

                if (name.isEmpty || course.isEmpty) return;

                try {
                  if (student == null) {
                    await DatabaseHelper.instance.insertStudent(name, course);
                  } else {
                    await DatabaseHelper.instance.updateStudent(
                      student['id'] as int,
                      name,
                      course,
                    );
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await loadStudents();
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    courseController.dispose();
  }

  Future<void> deleteStudent(int id) async {
    await DatabaseHelper.instance.deleteStudent(id);
    await loadStudents();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleStudents = filteredStudents;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStudentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadStudents,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7661A8), Color(0xFFAA8BCB)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LOCAL DATABASE',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Student Management Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${students.length} students stored locally',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or course...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Student Records',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${visibleStudents.length} found'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibleStudents.isEmpty)
                    const EmptyStudentRecords()
                  else
                    ...visibleStudents.map((student) {
                      return StudentRecordCard(
                        name: student['name'].toString(),
                        course: student['course'].toString(),
                        idLabel: 'ID: ${student['id']}',
                        onEdit: () => showStudentDialog(student: student),
                        onDelete: () => deleteStudent(student['id'] as int),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

// --------------------------------------------------
// PART B: FIREBASE CLOUD FIRESTORE
// --------------------------------------------------

class CloudStudentsPage extends StatefulWidget {
  const CloudStudentsPage({super.key});

  @override
  State<CloudStudentsPage> createState() => _CloudStudentsPageState();
}

class _CloudStudentsPageState extends State<CloudStudentsPage> {
  final FirebaseService firebaseService = FirebaseService();

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  Future<void> showCloudStudentDialog({
    String? documentId,
    String? existingName,
    String? existingCourse,
  }) async {
    final nameController = TextEditingController(text: existingName ?? '');

    final courseController = TextEditingController(text: existingCourse ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            documentId == null ? 'Add Cloud Student' : 'Edit Cloud Student',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final course = courseController.text.trim();

                if (name.isEmpty || course.isEmpty) return;

                try {
                  if (documentId == null) {
                    await firebaseService.addStudent(name, course);
                  } else {
                    await firebaseService.updateStudent(
                      documentId,
                      name,
                      course,
                    );
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        documentId == null
                            ? 'Student uploaded to Firestore!'
                            : 'Cloud record updated!',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Firestore error: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    courseController.dispose();
  }

  Future<void> deleteCloudStudent(String id) async {
    try {
      await firebaseService.deleteStudent(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud student deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCloudStudentDialog(),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Add Cloud Student'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firebaseService.getStudents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load Firestore records.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data?.docs ?? [];

          final filteredDocuments = documents.where((document) {
            final data = document.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final course = (data['course'] ?? '').toString().toLowerCase();
            final query = searchQuery.toLowerCase();

            return name.contains(query) || course.contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF62528E), Color(0xFF9A85C5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CLOUD DATABASE',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Firebase Student Records',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${documents.length} students stored in Firestore',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search cloud records...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cloud Student Records',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text('${filteredDocuments.length} found'),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredDocuments.isEmpty)
                const EmptyStudentRecords()
              else
                ...filteredDocuments.map((document) {
                  final data = document.data();

                  return StudentRecordCard(
                    name: (data['name'] ?? '').toString(),
                    course: (data['course'] ?? '').toString(),
                    idLabel: 'Cloud ID: ${document.id}',
                    onEdit: () => showCloudStudentDialog(
                      documentId: document.id,
                      existingName: (data['name'] ?? '').toString(),
                      existingCourse: (data['course'] ?? '').toString(),
                    ),
                    onDelete: () => deleteCloudStudent(document.id),
                  );
                }),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

// --------------------------------------------------
// REUSABLE STUDENT RECORD CARD
// --------------------------------------------------

class StudentRecordCard extends StatelessWidget {
  final String name;
  final String course;
  final String idLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentRecordCard({
    super.key,
    required this.name,
    required this.course,
    required this.idLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAE3F7),
          child: Text(
            name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF65508F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$course • $idLabel'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// EMPTY RECORDS MESSAGE
// --------------------------------------------------

class EmptyStudentRecords extends StatelessWidget {
  const EmptyStudentRecords({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.school_outlined, size: 45, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No student records found.',
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            'Add a student to get started!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
