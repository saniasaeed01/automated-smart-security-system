// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  GoogleMapController? mapController;
  Location location = Location();
  LocationData? _currentLocation;
  bool _isLoading = true;
  Set<Marker> markers = {};
  Marker? currentLocationMarker;

  // Default position (you can set this to any default location)
  final LatLng _defaultLocation =
      const LatLng(28.7041, 77.1025); // Delhi coordinates

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Check if permission is granted
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    try {
      final locationData = await location.getLocation();
      setState(() {
        _currentLocation = locationData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    if (_currentLocation != null && mapController != null) {
      final LatLng position = LatLng(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );

      // Update current location marker
      currentLocationMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: position,
        infoWindow: const InfoWindow(title: 'Current Location'),
      );

      // Update markers set
      setState(() {
        markers.clear(); // Clear all existing markers
        if (currentLocationMarker != null) {
          markers.add(currentLocationMarker!);
        }
        // If you need to show emergency contacts, add them here
        // markers.addAll(emergencyContactMarkers);
      });

      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 15,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Map'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation != null
                        ? LatLng(
                            _currentLocation!.latitude!,
                            _currentLocation!.longitude!,
                          )
                        : _defaultLocation,
                    zoom: 15,
                  ),
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.pinkAccent,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
