import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'admin_view.dart';
import 'user_view.dart';

class LoginView extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Connexion Admin')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            authController.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      bool success = await authController.login(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                      if (success && context.mounted) {
                        final user = authController.currentUser;
                        if (user!.isAdmin) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => AdminView()),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => UserView()),
                          );
                        }
                      }
                    },
                    child: Text('Se connecter'),
                  ),
            if (authController.errorMessage != null)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  authController.errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}