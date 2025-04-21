import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mychaty/methods.dart';
import 'package:mychaty/HomeScreen.dart'; // Ensure this file contains the HomeScreen class

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
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

              _buildTextField(size, "Nom", Icons.person_outline, false, _name),
              SizedBox(height: 20),
              _buildTextField(size, "Email", Icons.email_outlined, false, _email),
              SizedBox(height: 20),
              _buildTextField(size, "Mot de passe", Icons.lock_outline, true, _password),
              SizedBox(height: 20),

              SizedBox(height: size.height * 0.06),

              _buildCreateButton(size),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Déjà un compte ? Connectez-vous",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(Size size, String hintText, IconData icon, bool isPassword, TextEditingController cont) {
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
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildCreateButton(Size size) {
    return GestureDetector(
      onTap: () {
        if(_name.text.isNotEmpty && _email.text.isNotEmpty && _password.text.isNotEmpty) {
          setState(() {
            isLoading = true;
          });

          createAccount(_name.text, _email.text, _password.text)
              .then((user) {

                if(user != null) {
                  setState(() {
                    isLoading = false;
                  });
                  Navigator.push(
                    context, MaterialPageRoute(builder: (_) => HomeScreen()));
                  Logger().i("Compte créé avec succès");
                }else{
                  Logger().e("Échec de la création du compte");
                  setState(() {
                    isLoading = false;
                  });
                }
              });
        }else{
          Logger().i("Veuillez remplir tous les champs");
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
