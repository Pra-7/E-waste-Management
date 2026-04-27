import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class CollectorLocationService {
  static StreamSubscription<Position>? _positionStream;
  static bool _isTracking = false;

  /// Call this when a collector accepts a request.
  /// Starts streaming the collector's GPS location to Firestore every few seconds.
  /// When they come within [thresholdMeters] of the pickup point, auto-triggers "Arrived".
  static Future<void> startTracking({
    required String docId,
    required String userId,
    required double pickupLat,
    required double pickupLng,
    double thresholdMeters = 500,
    void Function(String message)? onError,
  }) async {
    if (_isTracking) await stopTracking();

    // Check / request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      onError?.call("Location permission denied. Cannot track position.");
      return;
    }

    _isTracking = true;

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // only update if moved 20m (saves battery)
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) async {
      final collectorId = FirebaseAuth.instance.currentUser?.uid;
      if (collectorId == null) return;

      // Update collector's live location in Firestore
      await FirebaseFirestore.instance
          .collection('pickup_requests')
          .doc(docId)
          .update({
        'collectorLat': position.latitude,
        'collectorLng': position.longitude,
        'collectorLastSeen': Timestamp.now(),
      });

      // Check distance to pickup point
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        pickupLat,
        pickupLng,
      );

      if (distanceMeters <= thresholdMeters) {
        // Auto-trigger "Arrived" status + send notification
        await _triggerArrived(docId, userId);
        await stopTracking(); // stop after arriving
      }
    }, onError: (e) {
      onError?.call("Location error: $e");
    });
  }

  /// Stop tracking (call on logout, or after arriving)
  static Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
  }

  static bool get isTracking => _isTracking;

  static Future<void> _triggerArrived(String docId, String userId) async {
    // Check current status first — don't double-trigger
    final doc = await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .get();

    final status = (doc.data() as Map<String, dynamic>?)?['status'];
    if (status == 'Arrived' || status == 'Completed') return;

    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .update({'status': 'Arrived'});

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'message': '🚚 Your collector is almost there! They are within 500m of your location.',
      'createdAt': Timestamp.now(),
    });
  }
}