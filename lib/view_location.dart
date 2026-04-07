import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ViewLocationPage extends StatelessWidget {
  final double lat;
  final double lng;
  final double? collectorLat;
  final double? collectorLng;

  const ViewLocationPage({
    super.key,
    required this.lat,
    required this.lng,
    this.collectorLat,
    this.collectorLng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Collector")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat, lng),
          initialZoom: 16,
        ),
        children: [

          /// MAP
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.e_waste_collector',
          ),

          /// MARKERS
          MarkerLayer(
            markers: [

              /// USER LOCATION
              Marker(
                point: LatLng(lat, lng),
                width: 40,
                height: 40,
                child: const Icon(Icons.location_pin,
                    color: Colors.red, size: 40),
              ),

              /// COLLECTOR LOCATION
              if (collectorLat != null && collectorLng != null)
                Marker(
                  point: LatLng(collectorLat!, collectorLng!),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.local_shipping,
                      color: Colors.blue, size: 40),
                ),
            ],
          ),

          /// LINE BETWEEN THEM
          if (collectorLat != null && collectorLng != null)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [
                    LatLng(collectorLat!, collectorLng!),
                    LatLng(lat, lng),
                  ],
                  strokeWidth: 4,
                  color: Colors.blue,
                ),
              ],
            ),
        ],
      ),
    );
  }
}