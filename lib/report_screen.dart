import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  List<File> _imageFiles = [];
  static const int maxImages = 5;
  Set<Circle> _circles = {};
  bool _isReporting = false;
  LatLng? _currentLocation; // Ubicación actual del usuario
  GoogleMapController? _mapController;
  String _selectedAddress = 'Selecciona un punto en el mapa';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadReports();
    _getCurrentLocation(); // Obtener la ubicación del usuario al iniciar
  }

  Future<void> _checkPermissions() async {
    var statusLocation = await Permission.locationWhenInUse.status;
    if (statusLocation.isDenied) {
      await Permission.locationWhenInUse.request();
    }

    var statusCamera = await Permission.camera.status;
    if (statusCamera.isDenied) {
      await Permission.camera.request();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentLocation!),
        );
      });
    } catch (e) {
      print('Error al obtener la ubicación actual: $e');
    }
  }

  Future<void> _loadReports() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('reports').get();

      Map<LatLng, int> reportCounts = {};

      for (var doc in snapshot.docs) {
        double lat = doc['latitude'];
        double lng = doc['longitude'];
        LatLng position = LatLng(lat, lng);

        reportCounts[position] = (reportCounts[position] ?? 0) + 1;
      }

      Set<Circle> circles = {};
      reportCounts.forEach((position, count) {
        Color color;
        if (count == 1) {
          color = Colors.yellow;
        } else if (count == 2) {
          color = Colors.orange;
        } else {
          color = Colors.red;
        }

        circles.add(Circle(
          circleId: CircleId(position.toString()),
          center: position,
          radius: 200,
          fillColor: color.withOpacity(0.5),
          strokeColor: color,
          strokeWidth: 2,
        ));
      });

      setState(() {
        _circles = circles;
      });
    } catch (e) {
      print('Error al cargar reportes: $e');
    }
  }

  Future<void> _uploadReport() async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'address': _selectedAddress,
        'latitude': _currentLocation?.latitude,
        'longitude': _currentLocation?.longitude,
        'type': _typeController.text,
        'comments': _commentsController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte enviado exitosamente.')),
      );

      setState(() {
        _imageFiles.clear();
        _selectedAddress = 'Selecciona un punto en el mapa';
        _commentsController.clear();
        _typeController.clear();
      });
      _loadReports();
    } catch (e) {
      print('Error al enviar reporte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el reporte.')),
      );
    }
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        if (_currentLocation != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15),
          );
        }
      },
      initialCameraPosition: CameraPosition(
        target: _currentLocation ??
            LatLng(23.6345, -102.5528), // México como predeterminado
        zoom: 5,
      ),
      circles: _circles,
      onTap: (position) async {
        setState(() {
          _currentLocation = position;
          _selectedAddress = "Ubicación seleccionada";
        });
      },
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: TextFormField(
            controller: _typeController,
            decoration: InputDecoration(
              labelText: 'Tipo de basura (Opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: TextFormField(
            controller: _commentsController,
            decoration: InputDecoration(
              labelText: 'Comentarios (Opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _uploadReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          child: Text(
            'Enviar Reporte',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReporting ? 'Hacer Reporte' : 'Mapa de Contaminación'),
        actions: [
          IconButton(
            icon: Icon(_isReporting ? Icons.map : Icons.add),
            onPressed: () {
              setState(() {
                _isReporting = !_isReporting;
              });
            },
          ),
        ],
      ),
      body: _isReporting
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildForm(),
            )
          : _buildMap(),
    );
  }
}
