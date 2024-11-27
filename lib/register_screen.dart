import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mock_transit_api.dart'; // Importar el modelo de datos simulado

class RegisterScreen extends StatefulWidget {
  final User user;

  RegisterScreen({required this.user});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'usuario';

  Future<void> _completeRegistration() async {
    if (_selectedRole == 'camionero') {
      // Validar los datos del camionero
      bool isValid = MockTransitAPI.verifyDriverData(
        _nameController.text.trim(),
        _plateNumberController.text.trim(),
        _phoneController.text.trim(),
      );

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Los datos ingresados no coinciden con los registros oficiales.',
            ),
          ),
        );
        return;
      }
    }

    try {
      // Datos base para todos los usuarios
      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': widget.user.email,
        'role': _selectedRole,
      };

      // Agregar datos adicionales para los camioneros
      if (_selectedRole == 'camionero') {
        userData['plateNumber'] = _plateNumberController.text.trim();
        userData['phone'] = _phoneController.text.trim();
      }

      // Guardar los datos del usuario en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(userData);

      // Navegar a la pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(userRole: _selectedRole),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al completar el registro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Completar Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text('Selecciona tu rol:', style: TextStyle(fontSize: 16)),
            RadioListTile(
              title: Text('Usuario'),
              value: 'usuario',
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            RadioListTile(
              title: Text('Camionero'),
              value: 'camionero',
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            if (_selectedRole == 'camionero') ...[
              SizedBox(height: 20),
              TextField(
                controller: _plateNumberController,
                decoration: InputDecoration(
                  labelText: 'Número de Placa',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Número de Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _completeRegistration,
              child: Text('Completar Registro'),
            ),
          ],
        ),
      ),
    );
  }
}
