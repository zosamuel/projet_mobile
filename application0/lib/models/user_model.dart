import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String status;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.status,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Gestion du createdAt (peut être String ou Timestamp)
    DateTime? createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.tryParse(data['createdAt']);
      }
    }
    
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? 'Sans nom',
      email: data['email'] ?? '',
      status: data['status'] ?? 'inactif',
      role: data['role'] ?? 'user',
      createdAt: createdAt,
    );
  }

  bool get isActive => status == 'actif';
  bool get isAdmin => role == 'admin';
}