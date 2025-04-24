import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mychaty/Auth/LoginScreen.dart';

Future<User?> createAccount(String name, String email, String password) async {
  final FirebaseAuth auth = FirebaseAuth.instance;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    if (user != null) {
      Logger().i("Compte créé avec succès");

      user.updateProfile(displayName: name);

      await firestore.collection('users').doc(auth.currentUser!.uid).set({
        "name": name,
        "email": email,
        "status": "Je suis nouveau sur Chaty",
      });

      return user;
    } else {
      Logger().e("Échec de la création du compte");
      return user;
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
      return user;
    }
  } catch (e) {
    Logger().e("Erreur lors de la connexion : $e");
    return null;
  }
}

Future logOut(BuildContext context) async {
  FirebaseAuth auth = FirebaseAuth.instance;

  try {
    await auth.signOut().then((value) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    });
  } catch (e) {
    Logger().e("Erreur lors de la déconnexion : $e");
  }
}
