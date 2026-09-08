import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth
  static Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Firestore - Users
  static Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  static Future<DocumentSnapshot> getUserById(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  static Future<void> updateUserStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).update({'status': status});
  }

  static Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  static Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  static Future<void> createUserWithAuth(String email, String password, String name, String role) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await createUser(userCredential.user!.uid, {
      'name': name,
      'email': email,
      'status': 'actif',
      'role': role,
      'createdAt': DateTime.now(),
    });
  }

  // Firestore - Audit Logs
  static Future<void> addAuditLog(String action, String targetUser, {String? details}) async {
    final admin = getCurrentUser();
    await _firestore.collection('auditLogs').add({
      'admin_email': admin?.email,
      'action': action,
      'target_user': targetUser,
      'details': details,
      'timestamp': DateTime.now(),
    });
  }

  static Stream<QuerySnapshot> getAuditLogsStream() {
    return _firestore.collection('auditLogs').orderBy('timestamp', descending: true).snapshots();
  }
}