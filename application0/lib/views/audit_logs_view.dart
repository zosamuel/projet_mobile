import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogsView extends StatelessWidget {
  AuditLogsView({super.key});  // ← plus de const

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal des actions'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auditLogs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final data = log.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(data['action'] ?? 'Action inconnue'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin : ${data['admin_email'] ?? 'Inconnu'}'),
                      Text('Cible : ${data['target_user'] ?? '-'}'),
                      if (data['details'] != null) Text('Détails : ${data['details']}'),
                      Text('Date : ${data['timestamp'] ?? DateTime.now()}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}