import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {

  LatLng selectedLocation = LatLng(27.7172, 85.3240);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),

      body: FlutterMap(
        options: MapOptions(
          initialCenter: selectedLocation,
          initialZoom: 13,

          onTap: (tapPosition, point) {
            setState(() {
              selectedLocation = point;
            });
          },
        ),

        children: [
          TileLayer(
             urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
             userAgentPackageName: 'com.example.e_waste_collector',
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_pin, color: Colors.red),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, {
            "lat": selectedLocation.latitude,
            "lng": selectedLocation.longitude,
            });
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}