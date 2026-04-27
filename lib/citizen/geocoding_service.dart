import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Convert lat/lng to a human-readable address using OpenStreetMap Nominatim (free, no API key)
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );

      final response = await http.get(
        uri,
        headers: {
          // Nominatim requires a User-Agent header
          'User-Agent': 'EcoPickupApp/1.0 (ewaste@example.com)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Build a clean short address: neighbourhood/suburb + city
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final parts = <String>[];

          // Try to get the most specific meaningful part first
          final road = address['road'] ?? address['pedestrian'] ?? address['path'];
          final neighbourhood = address['neighbourhood'] ??
              address['suburb'] ??
              address['village'] ??
              address['town'];
          final city = address['city'] ??
              address['municipality'] ??
              address['county'];
          final country = address['country'];

          if (road != null) parts.add(road as String);
          if (neighbourhood != null) parts.add(neighbourhood as String);
          if (city != null) parts.add(city as String);
          if (parts.isEmpty && country != null) parts.add(country as String);

          if (parts.isNotEmpty) return parts.join(', ');
        }

        // Fallback: use the display_name but truncate it
        final displayName = data['display_name'] as String?;
        if (displayName != null) {
          final segments = displayName.split(', ');
          // Return first 3 meaningful segments
          return segments.take(3).join(', ');
        }
      }
    } catch (e) {
      // Silently fall back to coordinates if geocoding fails
    }

    // Final fallback: coordinates
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}