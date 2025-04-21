import 'package:flutter/material.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
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
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              // Bouton retour
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              SizedBox(height: 10),

              Icon(Icons.person_add_alt_1, size: 80, color: Colors.blueAccent),

              SizedBox(height: 20),

              Text(
                "Créer un compte MyChaty",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),

              SizedBox(height: 10),

              Text(
                "Inscrivez-vous pour continuer 🚀",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),

              SizedBox(height: size.height * 0.06),

              _buildTextField(size, "Email", Icons.email_outlined, false),
              SizedBox(height: 20),
              _buildTextField(size, "Mot de passe", Icons.lock_outline, true),
              SizedBox(height: 20),
              _buildTextField(size, "Confirmer le mot de passe", Icons.lock_outline, true),

              SizedBox(height: size.height * 0.06),

              _buildCreateButton(size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(Size size, String hintText, IconData icon, bool isPassword) {
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
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildCreateButton(Size size) {
    return GestureDetector(
      onTap: () {
        // Logique de création de compte ici
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
          "Créer un compte",
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
