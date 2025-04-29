import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mychaty/Auth/Methods.dart';
import 'package:mychaty/Screens/ChatRoom.dart';
import 'package:mychaty/Screens/ProfileScreen.dart';

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
  String? profileImageUrl;
  List<Map<String, dynamic>> chatRooms = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
    loadUserDisplayName();
    loadChatRooms();
  }

  void loadChatRooms() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      firestore
          .collection('chatrooms')
          .where('users', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .listen((snapshot) {
        processChatRoomsSnapshot(snapshot, user.uid);
      });
    } catch (e) {
      Logger().e("Error loading chat rooms: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des discussions")),
      );
    }
  }

  void processChatRoomsSnapshot(QuerySnapshot snapshot, String currentUserId) async {
    List<Map<String, dynamic>> rooms = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String otherUserId = (data['users'] as List<dynamic>).firstWhere(
            (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty) {
        final userDoc = await firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          rooms.add({
            'chatRoomId': doc.id,
            'otherUser': userDoc.data(),
            'lastMessage': data['lastMessage'] ?? 'Nouvelle conversation',
            'lastMessageTime': data['lastMessageTime'],
          });
        }
      }
    }

    setState(() {
      chatRooms = rooms;
      isLoading = false;
    });
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
          profileImageUrl = data?['profileImageUrl'];
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen())
                      ).then((_) {
                        loadUserDisplayName();
                      });
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          radius: 20,
                          child: profileImageUrl == null
                              ? Icon(Icons.person, color: Colors.blueAccent)
                              : null,
                        ),
                        SizedBox(width: 8),
                        Text(
                          displayName ?? "Profile",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () => logOut(context),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chat_bubble_outlined, size: 60, color: Colors.blueAccent),

            const SizedBox(height: 15),

            Text(
              "Bienvenue dans MyChaty",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),

            const SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  _buildTextField(size),
                  SizedBox(height: 10),
                  _buildSearchButton(size),
                ],
              ),
            ),

            if (userMap != null)
              _buildUserTile(userMap!, _auth.currentUser!, size),

            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 10),
              child: Row(
                children: [
                  Text(
                    "Discussions récentes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const Spacer(),
                  if (chatRooms.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${chatRooms.length}",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _buildChatRoomsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatRoomsList() {
    if (chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
            SizedBox(height: 10),
            Text(
              "Aucune discussion récente",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Recherchez un utilisateur pour commencer à discuter",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.only(top: 10),
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatRooms[index];
          final otherUser = room['otherUser'] as Map<String, dynamic>;
          final lastMessage = room['lastMessage'] ?? '';
          final lastMessageTime = room['lastMessageTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(room['lastMessageTime'].millisecondsSinceEpoch)
              : null;
          final userStatus = otherUser['status'] ?? '';
          final userImage = otherUser['profileImageUrl'];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
            child: Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: userImage != null ? NetworkImage(userImage) : null,
                      radius: 25,
                      child: userImage == null ? Icon(Icons.person, color: Colors.blueAccent) : null,
                    ),
                    if (userStatus == "Online")
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  otherUser['name'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMessage.length > 30
                      ? "${lastMessage.substring(0, 30)}..."
                      : lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastMessageTime != null)
                      Text(
                        '${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    SizedBox(height: 5),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoom(
                        chatRoomId: room['chatRoomId'],
                        userMap: otherUser,
                      ),
                    ),
                  ).then((_) => loadChatRooms());
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(Size size) {
    return Container(
      width: size.width * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
        width: size.width * 0.9,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(15),
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
        ).then((_) => loadChatRooms());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              backgroundImage: userMap['profileImageUrl'] != null
                  ? NetworkImage(userMap['profileImageUrl'])
                  : null,
              radius: 25,
              child: userMap['profileImageUrl'] == null
                  ? Icon(Icons.account_circle, size: 25, color: Colors.blueAccent)
                  : null,
            ),
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
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: userMap['status'] == "Online" ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        userMap['status'] ?? "Statut inconnu",
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}