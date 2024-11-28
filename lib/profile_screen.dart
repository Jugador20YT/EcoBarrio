import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String? _name;
  String? _email;
  int _points = 0; // Puntos del usuario

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (_currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      setState(() {
        _name = userDoc['name'] ?? 'Usuario Desconocido';
        _email = userDoc['email'] ?? 'Correo no disponible';
        _points = userDoc.data()?.containsKey('points') == true
            ? userDoc['points']
            : 0;
// Supongamos que "points" está en Firestore
      });
    }
  }

  void _pickImage() {
    // Lógica futura para tomar o seleccionar una foto
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Funcionalidad no implementada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar para la foto del perfil
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Botones para tomar o seleccionar una foto
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.camera),
                  label: Text('Tomar Foto'),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo),
                  label: Text('Seleccionar Foto'),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Información del perfil
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Nombre'),
                subtitle: Text(_name ?? 'Cargando...'),
              ),
            ),
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.email),
                title: Text('Correo'),
                subtitle: Text(_email ?? 'Cargando...'),
              ),
            ),
            SizedBox(height: 20),
            // Sistema de puntos
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.star, color: Colors.yellow),
                title: Text('Puntos'),
                subtitle: Text('$_points puntos'),
                trailing: Text(
                  '${(_points * 0.1).toStringAsFixed(2)} MXN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
