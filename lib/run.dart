import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:runsplit/save_run.dart';

class Run extends StatefulWidget {
  const Run({super.key});

  @override
  State<Run> createState() => _RunState();
}

class _RunState extends State<Run> {
  final stopwatch = Stopwatch();
  bool displayStats = false;
  var dsplit = [0.0];
  var tsplit = [0.0];
  var currDistance = 0.0;
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  var speed = 0.0;
  var overallTime = 0.0;

  var totalTime = <String, int>{};
  var currTime = <String, int>{};
  var avgPace = <String, int>{};
  var splitPace = <String, int>{};
  var currPosition = <String, double>{};
  List<LatLng> positions = [];
  final Set<Polyline> _polylines = {};
  var initPosition;

  var currentSplitDuration = 0.0;
  var currentSplitDistance = 0.0;
  double dlat = 0.0, dlong = 0.0;
  var lats = [];
  var longs = [];

  late StreamSubscription<Position> positionStream;
  late GoogleMapController googleMapController;
  static const LatLng src = LatLng(37.1234567, -122.12345678);
  Position? currentPosition;

  Set<Marker> markers = {};

  void initVars() {
    totalTime["h"] = 0;
    totalTime["m"] = 0;
    totalTime["s"] = 0;

    currTime["h"] = 0;
    currTime["m"] = 0;
    currTime["s"] = 0;

    avgPace["m"] = 0;
    avgPace["s"] = 0;

    splitPace["m"] = 0;
    splitPace["s"] = 0;
  }

  @override
  void initState() {
    checkGps();
    getLocation();
    initVars();
    super.initState();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Terminate Run'),
            content: const Text(
                'Are you sure you want to exit? This unsaved activity will be lost!'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue Run'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Terminate Run'),
              ),
            ],
          ),
        )) ??
        false;
  }

  checkGps() async {
    servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
        } else if (permission == LocationPermission.deniedForever) {
          debugPrint("'Location permissions are permanently denied");
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }

      if (haspermission) {
        setState(() {});
        getLocation();
      }
    } else {
      debugPrint("GPS Service is not enabled, turn on GPS location");
    }

    setState(() {});
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currPosition['lat'] = position.latitude;
    currPosition['long'] = position.longitude;
    positions.add(LatLng(position.latitude, position.longitude));
    setState(() {});

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, //accuracy of the location data
      distanceFilter: 100, //minimum distance (measured in meters) a
      //device must move horizontally before an update event is generated;
    );

    // ignore: unused_local_variable
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      currentPosition = position;
      debugPrint(currentPosition!.latitude.toString() +
          currentPosition!.longitude.toString());
      currPosition['long'] = position.longitude;
      currPosition['lat'] = position.latitude;
      positions.add(LatLng(position.latitude, position.longitude));
      longs.add(currPosition['long']);
      lats.add(currPosition['lat']);
      if (longs.length > 1) {
        currDistance = currDistance +
            calculateDistance(lats[lats.length - 1], longs[longs.length - 1],
                lats[lats.length - 2], longs[longs.length - 2]);
      }
      speed = 60 / position.speed;

      currentSplitDuration =
          (stopwatch.elapsedMilliseconds / 1000 - tsplit[tsplit.length - 1]);
      currentSplitDistance = (currDistance - dsplit[dsplit.length - 1]);

      overallTime = stopwatch.elapsedMilliseconds / 1000.0;
      totalTime['h'] = (overallTime / 3600).floor();
      totalTime['m'] =
          (((overallTime / 3600) - totalTime['h']!) * 60.0).floor();
      totalTime['s'] = (((((overallTime / 3600) - totalTime['h']!) * 60.0) -
                  totalTime['m']!) *
              60.0)
          .floor();
      currTime['h'] = (currentSplitDuration / 3600).floor();
      currTime['m'] =
          (((currentSplitDuration / 3600) - currTime['h']!) * 60.0).floor();
      currTime['s'] =
          (((((currentSplitDuration / 3600) - currTime['h']!) * 60.0) -
                      currTime['m']!) *
                  60.0)
              .floor();

      avgPace['h'] = currDistance > 0.01
          ? (overallTime / (60.0 * currDistance)).floor()
          : 0;
      avgPace['m'] = currDistance > 0.01
          ? (((overallTime / (60.0 * currDistance)) -
                      (overallTime / (60.0 * currDistance)).floor()) *
                  60.0)
              .floor()
          : 0;
      splitPace['h'] = currentSplitDistance > 0.01
          ? (currentSplitDuration / (60.0 * currentSplitDistance)).floor()
          : 0;
      splitPace['m'] = currentSplitDistance > 0.01
          ? (((currentSplitDuration / (60.0 * currentSplitDistance)) -
                      (currentSplitDuration / (60.0 * currentSplitDistance))
                          .floor()) *
                  60.0)
              .floor()
          : 0;
      setState(() {});
    });
  }

  void createNewSplit() {
    tsplit.add(stopwatch.elapsedMilliseconds / 1000);
    dsplit.add(currDistance);
    currentSplitDistance = 0.0;
    currentSplitDuration = 0.0;
  }

  void stopRun() {
    tsplit.add(stopwatch.elapsedMilliseconds / 1000);
    dsplit.add(currDistance);
    stopwatch.stop();
  }

  void startRun() {
    dsplit = [0.0];
    tsplit = [0.0];
    displayStats = true;
    stopwatch.start();
  }

  getPolyLine() {
    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId("abc"),
        visible: true,
        //latlng is List<LatLng>
        points: positions,
        color: Colors.blue,
      ));
    });
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of the Earth in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadius * c;
    return distance;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            appBar: AppBar(
                title: const Text("Track Run"),
                backgroundColor: Colors.redAccent),
            body: currentPosition == null
                ? const Center(
                    child: Text("Loading..."),
                  )
                : Container(
                    alignment: Alignment.center,
                    child: Column(children: [
                      SizedBox(
                          height: 300,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                                target: LatLng(currentPosition!.latitude,
                                    currentPosition!.longitude),
                                zoom: 17),
                            mapType: MapType.normal,
                            markers: {
                              const Marker(
                                  markerId: MarkerId('start'), position: src)
                            },
                            zoomControlsEnabled: false,
                            myLocationEnabled: true,
                            onMapCreated: (GoogleMapController controller) {
                              googleMapController = controller;
                            },
                            //polylines: getPolyLine(),
                          )),
                      Text(
                        servicestatus ? "GPS is Enabled" : "GPS is disabled.",
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                          haspermission ? "GPS is Enabled" : "GPS is disabled.",
                          style: const TextStyle(fontSize: 10)),
                      const SizedBox(height: 20),
                      displayStats == false
                          ? Text("--")
                          : Text(
                              "Distance: ${currDistance.toStringAsFixed(3)} km",
                              style: const TextStyle(fontSize: 25),
                            ),
                      displayStats == false
                          ? Text("--")
                          : Text(
                              "Total time: ${(totalTime['h']!).toStringAsFixed(0)}h:${(totalTime['m']!).toStringAsFixed(0)}m:${(totalTime['s']!).toStringAsFixed(0)}s",
                              style: const TextStyle(fontSize: 25),
                            ),
                      displayStats == false
                          ? Text("--")
                          : Text(
                              // ignore: prefer_interpolation_to_compose_strings
                              "Average Pace: " +
                                  avgPace['h'].toString() +
                                  ":" +
                                  avgPace['m'].toString() +
                                  " min/km",
                              style: const TextStyle(fontSize: 25),
                            ),
                      const SizedBox(height: 40),
                      displayStats == false
                          ? Text("--")
                          : Text(
                              "Instantaneous speed: ${(speed).toStringAsFixed(1)} km/h",
                              style: const TextStyle(fontSize: 20),
                            ),
                      displayStats == false
                          ? Text("--")
                          : Text(
                              "Split pace: ${splitPace['h']}:${splitPace['m']} min/km",
                              style: const TextStyle(fontSize: 20),
                            ),
                      displayStats == false
                          ? Text("--")
                          : Text(
                              "Split duration: ${(currTime['h']!).toStringAsFixed(0)}h:${(currTime['m']!).toStringAsFixed(0)}m:${(currTime['s']!).toStringAsFixed(0)}s",
                              style: const TextStyle(fontSize: 20),
                            ),
                      displayStats == false
                          ? Text("--")
                          : Text(
                              // ignore: prefer_interpolation_to_compose_strings
                              "Split distance:" +
                                  currentSplitDistance.toStringAsFixed(3) +
                                  " km",
                              style: const TextStyle(fontSize: 20),
                            ),
                      const SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: displayStats ? null : startRun,
                            child: const Text("START"),
                          ),
                          const SizedBox(width: 30),
                          ElevatedButton(
                              onPressed: createNewSplit,
                              child: const Text("SPLIT")),
                          const SizedBox(width: 30),
                          ElevatedButton(
                              onPressed: () => {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SaveRun()))
                                  },
                              child: const Text("STOP"))
                        ],
                      ),
                    ]))));
  }
}
