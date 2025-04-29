import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isUpdating = false;
  File? _profileImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    setState(() => isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userData = doc.data();
            _nameController.text = userData?['name'] ?? '';
            _statusController.text = userData?['status'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      logger.e("Erreur lors du chargement des données: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() => isUpdating = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        await ref.putFile(_profileImage!);
        final downloadUrl = await ref.getDownloadURL();

        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': downloadUrl,
        });

        setState(() {
          userData = {...userData!, 'profileImageUrl': downloadUrl};
        });
      }
    } catch (e) {
      logger.e("Erreur lors de l'upload de l'image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour de l'image de profil")),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Future<void> updateProfile() async {
    if (_nameController.text.isEmpty || _statusController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => isUpdating = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'status': _statusController.text,
        });

        await user.updateProfile(displayName: _nameController.text);

        setState(() {
          userData = {
            ...userData!,
            'name': _nameController.text,
            'status': _statusController.text,
          };
        });

        if (_profileImage != null) {
          await uploadProfileImage();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil mis à jour avec succès")),
        );
      }
    } catch (e) {
      logger.e("Erreur lors de la mise à jour du profil: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour du profil")),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Mon Profil"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
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
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),

              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : userData?['profileImageUrl'] != null
                        ? NetworkImage(userData!['profileImageUrl'])
                        : null,
                    child: userData?['profileImageUrl'] == null && _profileImage == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),

              Container(
                width: size.width * 0.85,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      userData?['email'] ?? _auth.currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              Container(
                width: size.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Nom",
                    prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),

              SizedBox(height: 20),

              Container(
                width: size.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _statusController,
                  decoration: InputDecoration(
                    labelText: "Statut",
                    prefixIcon: Icon(Icons.info, color: Colors.blueAccent),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),

              SizedBox(height: 40),

              GestureDetector(
                onTap: isUpdating ? null : updateProfile,
                child: Container(
                  width: size.width * 0.85,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isUpdating ? Colors.grey : Colors.blueAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isUpdating
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Mettre à jour le profil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }
}