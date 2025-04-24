import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

class ChatRoom extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final String chatRoomId;

  const ChatRoom({Key? key, required this.chatRoomId, required this.userMap}) : super(key: key);

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final logger = Logger();

  File? imageFile;

  Future getImage() async {
    ImagePicker picker = ImagePicker();

    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      imageFile = File(xFile.path);
      uploadImage();
    }
  }

  Future uploadImage() async {
    String fileName = const Uuid().v1();
    var ref = FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    var uploadTask = await ref.putFile(imageFile!);
    String imageUrl = await uploadTask.ref.getDownloadURL();
    logger.i("Image téléchargée : $imageUrl");

    sendMessage(imageUrl, "image");
  }

  void sendMessage(String content, String type) async {
    if (content.trim().isEmpty) return;

    Map<String, dynamic> messages = {
      "sendby": _auth.currentUser!.uid,
      "message": content,
      "type": type,
      "time": FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .add(messages);
  }

  void onSendMessage() {
    if (_message.text.isNotEmpty) {
      sendMessage(_message.text, "text");
      _message.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un message")),
      );
    }
  }

  void deleteMessage(DocumentSnapshot doc, {required bool forEveryone}) async {
    if (forEveryone) {
      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(doc.id)
          .update({
        "message": "Ce message a été supprimé",
        "type": "text",
      });
    } else {
      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(doc.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userMap['name']),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatroom')
                  .doc(widget.chatRoomId)
                  .collection('chats')
                  .orderBy("time", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
                    return GestureDetector(
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.delete),
                                title: const Text("Supprimer pour moi"),
                                onTap: () {
                                  deleteMessage(doc, forEveryone: false);
                                  Navigator.pop(context);
                                },
                              ),
                              if (map['sendby'] == _auth.currentUser!.uid)
                                ListTile(
                                  leading: const Icon(Icons.delete_forever),
                                  title: const Text("Supprimer pour tous"),
                                  onTap: () {
                                    deleteMessage(doc, forEveryone: true);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                      child: messages(size, map),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: getImage,
                        icon: const Icon(Icons.photo),
                      ),
                      hintText: "Envoyer un message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: onSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget messages(Size size, Map<String, dynamic> map) {
    final isMe = map['sendby'] == _auth.currentUser!.uid;

    if (map['type'] == "text") {
      return Container(
        width: size.width,
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isMe ? Colors.blueAccent : Colors.grey[300],
          ),
          child: Text(
            map['message'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isMe ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    } else if (map['type'] == "image") {
      return Container(
        height: size.height / 2.5,
        width: size.width,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          height: size.height / 2.5,
          width: size.width / 2,
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.network(
            map['message'],
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
