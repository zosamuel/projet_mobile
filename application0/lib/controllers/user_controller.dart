import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserController extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _usersSubscription;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  void listenToUsers() {
    // Annule l'ancienne souscription si elle existe
    _usersSubscription?.cancel();
    
    _isLoading = true;
    notifyListeners();

    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  Future<bool> createUser(String name, String email, String password, String role, String adminEmail) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'status': 'actif',
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('ERREUR: $e');
      return false;
    }
  }

  Future<void> toggleUserStatus(UserModel user, String adminEmail) async {
    final newStatus = user.isActive ? 'inactif' : 'actif';
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'status': newStatus});
    await FirebaseFirestore.instance.collection('auditLogs').add({
      'admin_email': adminEmail,
      'action': 'Changement de statut',
      'target_user': user.email,
      'details': 'Nouveau statut : $newStatus',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> toggleUserRole(UserModel user, String adminEmail) async {
    final newRole = user.isAdmin ? 'user' : 'admin';
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': newRole});
    await FirebaseFirestore.instance.collection('auditLogs').add({
      'admin_email': adminEmail,
      'action': 'Changement de rôle',
      'target_user': user.email,
      'details': 'Nouveau rôle : $newRole',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> forceDisconnect(UserModel user, String adminEmail) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'status': 'inactif'});
    await FirebaseFirestore.instance.collection('auditLogs').add({
      'admin_email': adminEmail,
      'action': 'Déconnexion forcée',
      'target_user': user.email,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}