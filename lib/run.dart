import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class Run extends StatefulWidget {
  const Run({super.key});

  @override
  State<Run> createState() => _RunState();
}

class _RunState extends State<Run> {
  final stopwatch = Stopwatch();
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

  var currentSplitDuration = 0.0;
  var currentSplitDistance = 0.0;
  String long = "", lat = "";
  var lats = [];
  var longs = [];
  late StreamSubscription<Position> positionStream;

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
          print('Location permissions are denied');
        } else if (permission == LocationPermission.deniedForever) {
          print("'Location permissions are permanently denied");
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }

      if (haspermission) {
        setState(() {
          //refresh the UI
        });

        getLocation();
      }
    } else {
      print("GPS Service is not enabled, turn on GPS location");
    }

    setState(() {
      //refresh the UI
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    //print(position.longitude); //Output: 80.24599079
    //print(position.latitude); //Output: 29.6593457
    //speed = position.speed;
    long = position.longitude.toString();
    lat = position.latitude.toString();

    setState(() {
      //refresh UI
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, //accuracy of the location data
      distanceFilter: 100, //minimum distance (measured in meters) a
      //device must move horizontally before an update event is generated;
    );

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      longs.add(position.longitude);
      lats.add(position.latitude);
      if (longs.length > 1) {
        currDistance = currDistance +
            calculateDistance(lats[lats.length - 1], longs[longs.length - 1],
                lats[lats.length - 2], longs[longs.length - 2]);
      }
      speed = 60 / position.speed;
      long = position.longitude.toString();
      lat = position.latitude.toString();

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
      setState(() {
        //refresh UI on update
      });
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
    stopwatch.start();
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            appBar: AppBar(
                title: const Text("Track Run"),
                backgroundColor: Colors.redAccent),
            body: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(50),
                child: Column(children: [
                  Text(servicestatus ? "GPS is Enabled" : "GPS is disabled."),
                  Text(haspermission ? "GPS is Enabled" : "GPS is disabled."),
                  const SizedBox(height: 40),
                  Text(
                    "Distance: " + currDistance.toStringAsFixed(3) + " km",
                    style: const TextStyle(fontSize: 25),
                  ),
                  Text(
                    "Total time: " +
                        (totalTime['h']!).toStringAsFixed(0) +
                        "h:" +
                        (totalTime['m']!).toStringAsFixed(0) +
                        "m:" +
                        (totalTime['s']!).toStringAsFixed(0) +
                        "s",
                    style: const TextStyle(fontSize: 25),
                  ),
                  Text(
                    // ignore: prefer_interpolation_to_compose_strings
                    "Average Pace: " +
                        avgPace['h'].toString() +
                        ":" +
                        avgPace['m'].toString() +
                        " min/km",
                    style: const TextStyle(fontSize: 25),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Instantaneous speed: " +
                        (60 / speed).toStringAsFixed(3) +
                        " km/h",
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    "Split pace: " +
                        splitPace['h'].toString() +
                        ":" +
                        splitPace['m'].toString() +
                        " min/km",
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    "Split duration: " +
                        (currTime['h']!).toStringAsFixed(0) +
                        "h:" +
                        (currTime['m']!).toStringAsFixed(0) +
                        "m:" +
                        (currTime['s']!).toStringAsFixed(0) +
                        "s",
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
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
                          onPressed: createNewSplit,
                          child: const Text("SPLIT")),
                      const SizedBox(width: 30),
                      ElevatedButton(
                          onPressed: () => {}, child: const Text("STOP"))
                    ],
                  ),
                ]))));
  }
}
