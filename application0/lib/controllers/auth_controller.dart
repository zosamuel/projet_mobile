import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _errorMessage = 'Utilisateur non trouvé dans la base';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = UserModel.fromFirestore(userDoc);

      if (!_currentUser!.isActive) {
        await FirebaseAuth.instance.signOut();
        _errorMessage = '❌ Compte désactivé. Contactez l\'administrateur.';
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _listenToUserStatus(userCredential.user!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _listenToUserStatus(String uid) {
    _statusSubscription?.cancel();
    _statusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final status = doc.get('status');
        if (status != 'actif') {
          _forceLogoutBecauseInactive();
        }
      }
    });
  }

  void _forceLogoutBecauseInactive() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    _statusSubscription?.cancel();
    notifyListeners();
  }

  Future<void> logout() async {
    _statusSubscription?.cancel();
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}