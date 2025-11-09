// ignore_for_file: unused_field

import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  _LocationMapScreenState createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  Marker? _selectedMarker;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    LocationData locationData = await location.getLocation();
    setState(() {
      _currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);
      _selectedMarker = Marker(
        markerId: MarkerId('selected'),
        position: _currentLatLng!,
        draggable: true,
        onDragEnd: (pos) {
          setState(() {
            _selectedMarker = _selectedMarker!.copyWith(positionParam: pos);
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('লোকেশন নির্বাচন করুন'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _currentLatLng == null
            ? Center(child: CircularProgressIndicator())
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLatLng!,
                  zoom: 16,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _selectedMarker != null ? {_selectedMarker!} : {},
                onTap: (pos) {
                  setState(() {
                    _selectedMarker = Marker(
                      markerId: MarkerId('selected'),
                      position: pos,
                      draggable: true,
                      onDragEnd: (newPos) {
                        setState(() {
                          _selectedMarker =
                              _selectedMarker!.copyWith(positionParam: newPos);
                        });
                      },
                    );
                  });
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (_selectedMarker != null) {
              Navigator.pop(context, _selectedMarker!.position);
            }
          },
          label: Text('নির্বাচন করুন'),
          icon: Icon(Icons.check),
        ),
      ),
    );
  }
}
