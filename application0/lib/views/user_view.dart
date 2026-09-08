import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late StreamSubscription<DocumentSnapshot> _statusSubscription;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      final currentUser = authController.currentUser;
      
      if (currentUser != null) {
        _statusSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots()
            .listen((doc) {
          if (doc.exists && doc['status'] != 'actif') {
            _forceLogout();
          }
        });
      }
    });
  }

  void _forceLogout() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre compte a été désactivé par un administrateur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authController = Provider.of<AuthController>(context);
    final currentUser = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Text('Nom : ${currentUser?.name ?? "Inconnu"}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Email : ${currentUser?.email ?? "Inconnu"}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Statut : ', style: TextStyle(fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentUser?.isActive == true ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentUser?.status ?? "inactif",
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Rôle : ${currentUser?.role ?? "user"}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}