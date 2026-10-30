import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference<Map<String, dynamic>> students = FirebaseFirestore
      .instance
      .collection('students');

  // CREATE
  Future<void> addStudent(String name, String course) async {
    await students.add({
      'name': name,
      'course': course,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // READ
  Stream<QuerySnapshot<Map<String, dynamic>>> getStudents() {
    return students.orderBy('createdAt', descending: true).snapshots();
  }

  // UPDATE
  Future<void> updateStudent(String id, String name, String course) async {
    await students.doc(id).update({'name': name, 'course': course});
  }

  // DELETE
  Future<void> deleteStudent(String id) async {
    await students.doc(id).delete();
  }
}
