import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import 'add_user_view.dart';
import 'audit_logs_view.dart';

class AdminView extends StatefulWidget {
  @override
  _AdminViewState createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late StreamSubscription<DocumentSnapshot> _statusSubscription;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userController = Provider.of<UserController>(context, listen: false);
      userController.listenToUsers();
      
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
          content: Text('Vous avez été déconnecté par un administrateur'),
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
    final userController = Provider.of<UserController>(context);
    final currentUser = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Gestion des utilisateurs'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AuditLogsView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddUserView()),
              );
            },
          ),
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
      body: userController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userController.users.length,
              itemBuilder: (context, index) {
                final user = userController.users[index];
                final currentUser = authController.currentUser!;
                final isSelf = user.uid == currentUser.uid;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        Text(
                          'Rôle : ${user.role}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.status,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            user.isActive ? Icons.lock_outline : Icons.lock_open,
                            color: user.isActive ? Colors.red : Colors.green,
                          ),
                          onPressed: () async {
                            await userController.toggleUserStatus(
                              user,
                              currentUser.email,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${user.name} est maintenant ${user.isActive ? "inactif" : "actif"}',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        if (!isSelf)
                          IconButton(
                            icon: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                            onPressed: () async {
                              await userController.toggleUserRole(
                                user,
                                currentUser.email,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${user.name} est maintenant ${user.role == "admin" ? "user" : "admin"}',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        if (!isSelf)
                          IconButton(
                            icon: const Icon(Icons.power_settings_new, color: Colors.red),
                            onPressed: () async {
                              await userController.forceDisconnect(
                                user,
                                currentUser.email,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${user.name} a été déconnecté'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}