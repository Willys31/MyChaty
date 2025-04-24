import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mychaty/Auth/Methods.dart';
import 'package:mychaty/Screens/ChatRoom.dart';

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? displayName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
    loadUserDisplayName();
  }

  void setStatus(String status) async {
    final user = _auth.currentUser;
    if (user != null) {
      await firestore.collection('users').doc(user.uid).update({
        "status": status,
      });
    }
  }

  void loadUserDisplayName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          displayName = data?['name'];
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
    } else {
      setStatus("Offline");
    }
  }

  String chatRoomIdByUID(String uid1, String uid2) {
    return uid1.compareTo(uid2) > 0 ? "$uid1$uid2" : "$uid2$uid1";
  }

  void onSearch() async {
    final searchText = _search.text.trim();
    if (searchText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez entrer un nom à rechercher.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await firestore
          .collection('users')
          .where("name", isEqualTo: searchText)
          .get();

      if (result.docs.isNotEmpty) {
        setState(() {
          userMap = result.docs.first.data();
          userMap!['uid'] = result.docs.first.id;
          isLoading = false;
        });

        if (userMap!['uid'] == _auth.currentUser!.uid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Vous ne pouvez pas discuter avec vous-même.")),
          );
          setState(() => userMap = null);
        }
      } else {
        setState(() {
          userMap = null;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Aucun utilisateur trouvé.")),
        );
      }
    } catch (e) {
      Logger().e("Erreur lors de la recherche : $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
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
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    // Bouton logout
                    Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        onPressed: () => logOut(context),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Icon(Icons.home, size: 80, color: Colors.blueAccent),

                    const SizedBox(height: 20),

                    Text(
                      "Bienvenue dans MyChaty",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (displayName != null)
                      Text(
                        "Connecté en tant que : $displayName",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    SizedBox(height: size.height * 0.06),

                    _buildTextField(size),
                    SizedBox(height: 20),
                    _buildSearchButton(size),
                    SizedBox(height: size.height * 0.03),

                    if (userMap != null)
                      _buildUserTile(userMap!, _auth.currentUser!, size),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(Size size) {
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
        controller: _search,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
          hintText: "Rechercher un utilisateur",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSearchButton(Size size) {
    return GestureDetector(
      onTap: onSearch,
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
          "Rechercher",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> userMap, User currentUser, Size size) {
    return GestureDetector(
      onTap: () {
        final roomId = chatRoomIdByUID(currentUser.uid, userMap['uid']);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatRoom(
              chatRoomId: roomId,
              userMap: userMap,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.account_box, size: 40, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userMap['name'],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    userMap['email'],
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chat, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
