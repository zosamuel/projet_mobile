import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';

class AddUserView extends StatefulWidget {
  @override
  _AddUserViewState createState() => _AddUserViewState();
}

class _AddUserViewState extends State<AddUserView> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'user';
  bool isLoading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final userController = Provider.of<UserController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un utilisateur'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: InputDecoration(
                labelText: 'Rôle',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'user', child: Text('Utilisateur normal')),
                DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
              ],
              onChanged: (value) => setState(() => selectedRole = value!),
            ),
            SizedBox(height: 30),
            if (errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
              ),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      
                      bool success = await userController.createUser(
                        nameController.text.trim(),
                        emailController.text.trim(),
                        passwordController.text.trim(),
                        selectedRole,
                        authController.currentUser!.email,
                      );
                      
                      setState(() => isLoading = false);
                      
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ Utilisateur créé avec succès !')),
                        );
                      } else {
                        setState(() {
                          errorMessage = '❌ Erreur : vérifie ta connexion internet ou les règles Firebase';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text('Créer l\'utilisateur'),
                  ),
          ],
        ),
      ),
    );
  }
}