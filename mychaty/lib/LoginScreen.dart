import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mychaty/CreateAccount.dart';
import 'package:mychaty/HomeScreen.dart';
import 'package:mychaty/methods.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _email= TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: isLoading
      ? Center(
        child: Container(
          height: size.height / 20,
          width: size.width / 20,
          child: CircularProgressIndicator(),
        ),
        ): Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.1),

              // Logo ou Icone
              Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blueAccent),

              SizedBox(height: 20),

              Text(
                "Bienvenue sur MyChaty",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),

              SizedBox(height: 8),

              Text(
                "Connectez-vous pour discuter 👋",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),

              SizedBox(height: size.height * 0.08),

              _buildTextField(size, "Email", Icons.email_outlined, false, _email),
              SizedBox(height: 20),
              _buildTextField(size, "Mot de passe", Icons.lock_outline, true, _password),

              SizedBox(height: size.height * 0.06),

              _buildLoginButton(size),

              SizedBox(height: 30),

              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreateAccount()));
                },
                child: Text(
                  "Créer un compte",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      Size size, String hintText, IconData icon, bool isPassword, TextEditingController cont) {
    return Container(
      width: size.width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: cont,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildLoginButton(Size size) {
    return GestureDetector(
      onTap: () {
        if(_email.text.isNotEmpty && _password.text.isNotEmpty) {
          setState(() {
            isLoading = true;
          });

          logIn(_email.text, _password.text).then((user) {
            if (user != null) {
              Logger().i("Connexion réussie");
              setState(() {
                isLoading = false;
              });
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => HomeScreen()));
            } else {
              Logger().e("Erreur de connexion");
              setState(() {
                isLoading = false;
              });
            }
          });
        }else{
          Logger().e("Remplissez tous les champs");
        }
      },
      child: Container(
        width: size.width * 0.85,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          "Se connecter",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
