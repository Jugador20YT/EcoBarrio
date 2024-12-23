import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController mapController;
  LatLng _userPosition = LatLng(0, 0); // Posición del usuario
  Map<String, LatLng> _camionerosLocations =
      {}; // Ubicaciones de los camioneros
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref().child('locations');
  String _nextPassageMessage = 'Cargando información...';
  Map<String, String> _camionerosNames =
      {}; // Map para los nombres de camioneros

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Obtener ubicación del usuario
    _listenToCamionerosLocations(); // Escuchar las ubicaciones de los camioneros
    _fetchNextCamionPassage(); // Obtener la próxima hora de paso
  }

  Future<void> _getUserLocation() async {
    // Solicitar permisos de ubicación
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente.');
    }

    // Obtener la ubicación actual
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = LatLng(position.latitude, position.longitude);
    });

    // Centrar el mapa en la ubicación del usuario
    mapController.animateCamera(
      CameraUpdate.newLatLng(_userPosition),
    );
  }

  void _listenToCamionerosLocations() {
    // Escuchar cambios en las ubicaciones de los camioneros
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        Map<String, LatLng> updatedLocations = {};
        Map<String, String> camioneroNames = {}; // Para guardar los nombres

        data.forEach((key, value) {
          updatedLocations[key] = LatLng(
            value['latitude'] as double,
            value['longitude'] as double,
          );

          // Guardar el nombre del camionero
          camioneroNames[key] = value['name'] as String? ?? 'Desconocido';
        });

        setState(() {
          _camionerosLocations = updatedLocations;

          // Actualizar los nombres en los marcadores
          _camionerosNames = camioneroNames;
        });
      }
    });
  }

  Future<void> _fetchNextCamionPassage() async {
    try {
      final DateTime now = DateTime.now();
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('schedule')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('date')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final nextSchedule = snapshot.docs.first.data() as Map<String, dynamic>;
        final Timestamp dateTimestamp = nextSchedule['date'];
        final String time = nextSchedule['time'];

        final DateTime scheduledDate = dateTimestamp.toDate();
        final bool isToday = scheduledDate.day == now.day &&
            scheduledDate.month == now.month &&
            scheduledDate.year == now.year;

        setState(() {
          _nextPassageMessage = isToday
              ? 'Atención: El camión pasará hoy a las $time.'
              : 'Atención: El camión pasará el ${scheduledDate.day}/${scheduledDate.month} a las $time.';
        });
      } else {
        setState(() {
          _nextPassageMessage =
              'No hay horarios programados próximamente. Consulta más tarde.';
        });
      }
    } catch (e) {
      setState(() {
        _nextPassageMessage =
            'Error al obtener la información del próximo paso del camión.';
      });
    }
  }

  Set<Marker> _buildMarkers() {
    // Crear marcadores para todas las ubicaciones de camioneros
    return _camionerosLocations.entries.map((entry) {
      final String camioneroName = _camionerosNames[entry.key] ?? 'Desconocido';

      return Marker(
        markerId: MarkerId(entry.key),
        position: entry.value,
        infoWindow: InfoWindow(
          title: 'Camionero: $camioneroName',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rastreo de Camioneros',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            color: Colors.teal.shade50,
            child: Text(
              _nextPassageMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: GoogleMap(
                onMapCreated: (controller) => mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _userPosition,
                  zoom: 14.0,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _buildMarkers(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
