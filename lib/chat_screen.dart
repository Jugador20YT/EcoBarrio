import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference _chatCollection =
      FirebaseFirestore.instance.collection('chat');

  Future<void> _sendMessage() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor, inicia sesión para enviar mensajes.')),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) return;

    // Agregar mensaje a Firestore
    await _chatCollection.add({
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'sender': currentUser.email ?? 'Usuario Desconocido',
      'userId': currentUser.uid, // Guardar el UID del usuario
    });

    // Limpiar el campo de texto
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat General'),
      ),
      body: Column(
        children: [
          // Mostrar mensajes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatCollection
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Aún no hay mensajes. ¡Sé el primero en escribir!',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Construir la lista de mensajes
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final messageText = messageData['message'] ?? '';
                    final sender = messageData['sender'] ?? 'Desconocido';
                    final senderId = messageData['userId'] ?? '';

                    // Alinear los mensajes a la derecha si son del usuario actual
                    final isMyMessage = senderId == currentUser?.uid;

                    return Align(
                      alignment: isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMyMessage
                              ? Colors.green[100]
                              : Colors.grey[300], // Diferente color
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                            bottomLeft: isMyMessage
                                ? Radius.circular(10)
                                : Radius.circular(0),
                            bottomRight: isMyMessage
                                ? Radius.circular(0)
                                : Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMyMessage
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              sender,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isMyMessage ? Colors.green : Colors.black,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              messageText,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Campo de entrada de mensajes
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
