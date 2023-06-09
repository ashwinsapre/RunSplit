import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(35.783043093973134, -78.68919631953302), zoom: 14);

  late GoogleMapController googleMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("History"),
        ),
        body: Center(
          child: Column(children: [
            SizedBox(
                width: MediaQuery.of(context)
                    .size
                    .width, // or use fixed size like 200
                height: MediaQuery.of(context).size.height,
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: initialCameraPosition,
                ))
          ]),
        ));
  }
}
