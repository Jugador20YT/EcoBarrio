import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CamionerosScreen extends StatefulWidget {
  final String userId;
  final Function(bool) onLock;

  CamionerosScreen({required this.userId, required this.onLock});

  @override
  _CamionerosScreenState createState() => _CamionerosScreenState();
}

class _CamionerosScreenState extends State<CamionerosScreen> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref().child('locations');
  Stream<Position>? _positionStream;
  late GoogleMapController mapController;
  LatLng _currentPosition = LatLng(19.4326, -99.1332); // Coordenadas iniciales
  bool _isTracking = false;
  bool _isMapExpanded = true;
  String? _name;
  String? _plateNumber;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _fetchCamioneroData(); // Cargar datos del camionero
    _startUpdatingLocation(); // Iniciar la actualización de ubicación
  }

  /// Método para recuperar datos del camionero desde Firestore
  Future<void> _fetchCamioneroData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _name = userDoc['name'];
          _plateNumber = userDoc['plateNumber'];
          _phone = userDoc['phone'];
        });
      }
    } catch (e) {
      print('Error fetching camionero data: $e');
    }
  }

  /// Método para manejar el seguimiento de ubicación
  void _startUpdatingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('El servicio de ubicación está deshabilitado.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'El permiso de ubicación ha sido denegado permanentemente.');
    }

    _positionStream = Geolocator.getPositionStream();
    _positionStream?.listen((Position position) {
      _currentPosition = LatLng(position.latitude, position.longitude);

      if (_isTracking) {
        _databaseRef.child(widget.userId).set({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });

        if (mapController != null) {
          mapController.animateCamera(
            CameraUpdate.newLatLng(_currentPosition),
          );
        }
      }

      setState(() {});
    });
  }

  /// Método para alternar el estado de seguimiento
  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });
    widget.onLock(_isTracking);
  }

  /// Método para alternar el estado del mapa (plegado/desplegado)
  void _toggleMapExpansion() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camionero: ${_name ?? 'Cargando...'}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchCamioneroData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapa plegable/desplegable
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _isMapExpanded ? 300 : 150,
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: {
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: _currentPosition,
                  infoWindow: InfoWindow(title: 'Mi ubicación'),
                ),
              },
            ),
          ),
          // Botón para alternar mapa
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _toggleMapExpansion,
              icon: Icon(
                _isMapExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(_isMapExpanded ? 'Plegar Mapa' : 'Desplegar Mapa'),
            ),
          ),
          // Información del camionero
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Camionero',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Nombre'),
                    subtitle: Text(_name ?? 'Cargando...'),
                  ),
                  ListTile(
                    leading: Icon(Icons.directions_car),
                    title: Text('Número de Placa'),
                    subtitle: Text(_plateNumber ?? 'Cargando...'),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('Teléfono'),
                    subtitle: Text(_phone ?? 'Cargando...'),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _toggleTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isTracking ? Colors.red : Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(
                        _isTracking
                            ? 'Finalizar Recorrido'
                            : 'Empezar Recorrido',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
