import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:truckngo/models/driver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:truckngo/services/auth_service.dart';
import 'package:uuid/uuid.dart';

import '../models/ride.dart';

Future<Stream<Driver?>> findDriversAvailble(
    {required double longitude, required double latitude}) async {
  Geoflutterfire geo = Geoflutterfire(); // Create a geoFirePoint
  GeoFirePoint center = geo.point(latitude: latitude, longitude: longitude);
  double radius = 50;
  StreamController<Driver?> driversList = StreamController();

  Stream<List<DocumentSnapshot>> driversDoc = geo
      .collection(
          collectionRef:
              FirebaseFirestore.instance.collection('DriverLocation'))
      .within(center: center, radius: radius, field: 'position');

  driversDoc.listen((List<DocumentSnapshot> docs) {
    for (var doc in docs) {
      final docMap = doc.data() as Map<String, dynamic>;
      final GeoPoint point = docMap['position']['geopoint'];
      driversList.add(Driver(((b) => b
        ..name = docMap['name']
        ..id = doc.id
        ..latitude = point.latitude
        ..longitude = point.longitude
        ..driverImage = docMap['driverImage']
        ..numberPlate = docMap['numberPlate']
        ..truckType = docMap['truckType']
        ..carImage = docMap['carImage'])));
    }
  });
  return driversList.stream;
}

Future<void> createRide(Ride ride,String? destinationPlaceName,String? pickUpPlaceName) async {
  String uid = Uuid().v1();
  DatabaseReference ref = FirebaseDatabase.instance.ref("rideRequest/$uid");

  Map pickupMap = {
    'latitude': ride.pickUpLatitude,
    'longitude': ride.pickUpLongitude,
  };

  Map destinationMap = {
    'latitude': ride.destinationLatitude,
    'longitude': ride.destinationLongitude,
  };

  Map rideMap = {
    'created_at': DateTime.now().toString(),
    'rider_id': ride.riderId,
    'location': pickupMap,
    'destination': destinationMap,
    'payment_method': ride.paymentMethod,
    'driver_id': ride.driverId,
    'price': ride.price,
    'email': AuthService.instance.currentUser?.email,
    'status': 'waiting',
    'destination_place_name': destinationPlaceName,
    'pickup_place_name': pickUpPlaceName
  };

  await ref.set(rideMap);

  return;
}
