
import 'dart:async';

import 'package:battery_info/model/android_battery_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:battery_info/battery_info_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Police',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {

      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}
class _MyHomePageState extends State<MyHomePage> {

  List<double> _counter=[0,1];
  int p = 0;
 @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _determinePosition().then((result) {
      print(result);
      setState(() {
        p++;
        _counter[0] = result.latitude;
        _counter[1] = result.longitude;
      });
    });


 }

  Future<dynamic> getAccuracy() async {
    var accuracy = await Geolocator.getLocationAccuracy();
    return accuracy;
  }
  @override
  Widget build(BuildContext context) {

    late LocationSettings locationSettings;
    TargetPlatform d = defaultTargetPlatform;
    if(d == TargetPlatform.android) {
      locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 10),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
            "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Running in Background",
            enableWakeLock: true,
          )
      );
    }
    else{
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<AndroidBatteryInfo?>(
                stream: BatteryInfoPlugin().androidBatteryInfoStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData ) {
                    return Column(
                      children: [
                        Text("Voltage: ${(snapshot.data?.voltage)} mV"),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                            "Charging status: ${(snapshot.data?.chargingStatus.toString().split(".")[1])}"),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                            "Battery Level: ${(snapshot.data?.batteryLevel)} %"),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                            "Battery Capacity: ${(snapshot.data?.batteryCapacity)} mAh"),
                        SizedBox(
                          height: 20,
                        ),
                        Text("Technology: ${(snapshot.data?.technology)} "),
                        SizedBox(
                          height: 20,
                        ),
                        Text("Scale: ${(snapshot.data?.scale)} "),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    );
                  }
                  return CircularProgressIndicator();
                }),
        StreamBuilder<Position?>(
        stream: Geolocator.getPositionStream(locationSettings: locationSettings),
        builder: (context, position) {
          if (position.hasData){
            p++;
            Position? pos = position.data;
            return  Column(
            children: [
              Text("Longitude: ${(pos?.longitude)}"),
              SizedBox(
              height: 20,
            ),
              Text(
                "Latitude: ${pos?.latitude}"),
              SizedBox(
              height: 20,
            ),
    ]);
        }
            return CircularProgressIndicator();
        }
        ),
            FutureBuilder<LocationAccuracyStatus>(
              future: Geolocator.getLocationAccuracy(),
              builder: (context, snapshot) {

                  if (snapshot.hasData ) {
                  return Column(
                  children: [
                  Text("Accuracy: ${(snapshot.data)}"),
                  SizedBox(
                      height: 20,
                    ),
                  ],
                  );
                  }
                  return CircularProgressIndicator();
              }),
    ],
    )));
  }
}
