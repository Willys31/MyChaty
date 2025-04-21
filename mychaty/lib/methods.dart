import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mychaty/LoginScreen.dart';

Future<User?> createAccount(String name, String email, String password) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  try {
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    if (user != null) {
      Logger().i("Compte créé avec succès");
      await user.updateDisplayName(name);
      return user;
    } else {
      Logger().e("Échec de la création du compte");
      return null;
    }
  } catch (e) {
    Logger().e("Erreur lors de la création du compte : $e");
    return null;
  }
}

Future<User?> logIn(String email, String password) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  try {
    UserCredential userCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    if (user != null) {
      Logger().i("Connexion réussie");
      return user;
    } else {
      Logger().e("Erreur de connexion");
      return null;
    }
  } catch (e) {
    Logger().e("Erreur lors de la connexion : $e");
    return null;
  }
}

Future logOut(BuildContext context) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  try {
    await auth.signOut().then((value) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    });
    Logger().i("Déconnexion réussie");
  } catch (e) {
    Logger().e("Erreur lors de la déconnexion : $e");
  }
}
