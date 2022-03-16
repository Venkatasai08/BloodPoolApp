import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:bloodpool/main.dart';
import 'package:bloodpool/map_screen.dart';
import 'package:bloodpool/profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent/android_intent.dart';

class SearchScreen extends StatefulWidget {
  final String? username;
  // final String? mobile;
  const SearchScreen({Key? key, this.username}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // final PermissionHandler permissionHandler = PermissionHandler();
  // Map<PermissionGroup, PermissionStatus> permissions;
  Random random = Random();
  List allDonors = [];
  List searchDonors = [];
  String? sometext = "No Results Found";
  String? selectedBlood;
  Position? myLatPosition;
  GoogleMapController? newGoogleMapController;

  @override
  initState() {
    super.initState();
    getData();
    // requestLocationPermission();
    requestLocationPermission();
    _gpsService();
    _getGeoLocationPosition();
  }

  searchData(String bloodgroup) async {
    sometext = "Loading...";
    Future.delayed(const Duration(seconds: 7), () {
      setState(() {
        sometext = "No Results Found";
      });
    });

    var paramsData = bloodgroup;
    final response = await http.get(Uri.parse(
        'https://bloodpool-backend.herokuapp.com/search/$paramsData'));
    try {
      var responseData = json.decode(response.body);
      setState(() {
        searchDonors = responseData;
        allDonors = searchDonors;
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Database Error, Please report to bloodpool team');
    }
  }

  getData() async {
    sometext = "Loading...";
    Future.delayed(const Duration(seconds: 7), () {
      setState(() {
        sometext = "No Results Found";
      });
    });
    final response = await http
        .get(Uri.parse('https://bloodpool-backend.herokuapp.com/find'));

    var responseData = json.decode(response.body);
    setState(() {
      allDonors = responseData;
    });

    // allDonors = responseData[]
  }

  updateLocation() async {
    Future.delayed(const Duration(seconds: 5), () async {
      final response = await http.put(
          Uri.parse(
              'https://bloodpool-backend.herokuapp.com/update/location/${widget.username}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(
            <String, double>{
              "latitude": myLatPosition!.latitude,
              "longitude": myLatPosition!.longitude
            },
          ));
      // var responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Location Updated!!');
      } else {
        Fluttertoast.showToast(msg: 'Location not updated!!');
      }
    });
  }

  void locateMyPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    setState(() {
      myLatPosition = position;
    });
    updateLocation();
  }

  void _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(
            msg: 'Location permissions are denied.\nEnable to continue');
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
    locateMyPosition();
  }

  Future<void> requestLocationPermission() async {
    final serviceStatusLocation = await Permission.locationWhenInUse.isGranted;

    final status = await Permission.locationWhenInUse.request();

    if (status == PermissionStatus.granted) {
      print('Permission Granted');
    } else if (status == PermissionStatus.denied) {
      print('Permission denied');
      Fluttertoast.showToast(
        msg: 'Please Allow us the Location permission and restart the app',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM_LEFT,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.greenAccent,
        textColor: Colors.white,
      );
    } else if (status == PermissionStatus.permanentlyDenied) {
      print('Permission Permanently Denied');
      // await openAppSettings();
    }
  }

  Future _checkGps() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Can't get gurrent location"),
                content:
                    const Text('Please make sure you enable GPS and try again'),
                actions: <Widget>[
                  TextButton(
                      child: const Text('Ok'),
                      onPressed: () {
                        const AndroidIntent intent = AndroidIntent(
                            action:
                                'android.settings.LOCATION_SOURCE_SETTINGS');
                        intent.launch();
                        Navigator.of(context, rootNavigator: true).pop();
                        _gpsService();
                      })
                ],
              );
            });
      }
    }
  }

/*Check if gps service is enabled or not*/
  Future _gpsService() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      _checkGps();
      return null;
    } else {
      return true;
    }
  }

  Future<bool> _onBackPressed() async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Are you sure?'),
              content: const Text('Do you want to exit an App'),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                ElevatedButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    // Navigator.of(context).pop(true);
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else if (Platform.isIOS) {
                      exit(0);
                    }
                  },
                )
              ],
            );
          },
        ) ??
        false;
  }

  removeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("email");
    prefs.remove("username");
    prefs.remove("password");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.red[800],
            title: Text(
                widget.username != null
                    ? "${widget.username}'s BloodPool"
                    : 'Emergency BloodPool',
                style: const TextStyle(
                  color: Colors.white,
                )),
            centerTitle: widget.username != null ? false : true,
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      removeValues();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyHomePage(
                                title: 'Welcome to BloodPool')),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          size: 26.0,
                        ),
                        widget.username != null
                            ? const Text('Logout',
                                style: TextStyle(fontWeight: FontWeight.bold))
                            : const Text(''),
                      ],
                    ),
                  )),
            ]),
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 15.0, bottom: 15, right: 15, left: 15),
                        child: DropdownButton(
                            isExpanded: true,
                            underline: const SizedBox(),
                            alignment: Alignment.center,
                            icon: const Icon(Icons.arrow_drop_down_circle),
                            iconEnabledColor: Colors.red.shade800,
                            dropdownColor: Colors.white,
                            value: selectedBlood,
                            // elevation: 5,
                            items: [
                              DropdownMenuItem(
                                child: Center(
                                  child: Text("A+",
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w800)),
                                ),
                                value: 'A+',
                              ),
                              DropdownMenuItem(
                                child: Center(
                                  child: Text("B+",
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w800)),
                                ),
                                value: 'B+',
                              ),
                              DropdownMenuItem(
                                child: Center(
                                  child: Text("O+",
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w800)),
                                ),
                                value: 'O+',
                              ),
                              DropdownMenuItem(
                                child: Center(
                                  child: Text("AB+",
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w800)),
                                ),
                                value: 'AB+',
                              ),
                              DropdownMenuItem(
                                child: Center(
                                  child: Text("O-",
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w800)),
                                ),
                                value: 'O-',
                              )
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                selectedBlood = value;
                              });
                              searchData(selectedBlood!);
                            },
                            hint: Text(" Search Blood Group",
                                style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const Text('Search in Map : ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            selectedBlood != null ? Colors.blue : Colors.grey),
                        // padding: MaterialStateProperty.all(EdgeInsets.all(10)),
                        // textStyle:
                        // MaterialStateProperty.all(TextStyle(fontSize: 10))
                      ),
                      onPressed: () {
                        if (selectedBlood == null) {
                          Fluttertoast.showToast(
                            msg: 'Please select bloodgroup',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM_LEFT,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.greenAccent,
                            textColor: Colors.white,
                          );
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MapScreen(
                                      bloodgroup: selectedBlood,
                                      userPosition: myLatPosition)));
                        }
                      },
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: allDonors.isNotEmpty
                      ? ListView.builder(
                          itemCount: allDonors.length,
                          itemBuilder: (context, index) {
                            allDonors.sort((a, b) =>
                                (a['latitude'] != null && a['longitude'] != null
                                        ? Geolocator.distanceBetween(
                                            myLatPosition!.latitude,
                                            myLatPosition!.longitude,
                                            a['latitude'],
                                            a['longitude'])
                                        : double.infinity)
                                    .compareTo(b['latitude'] != null &&
                                            b['longitude'] != null
                                        ? Geolocator.distanceBetween(
                                            myLatPosition!.latitude,
                                            myLatPosition!.longitude,
                                            b['latitude'],
                                            b['longitude'])
                                        : double.infinity));
                            // print(sortedItems);
                            // items = sortedItems[index];
                            return Card(
                              // key: ValueKey(allDonors.isNotEmpty ? allDonors[index]["bloodgroup"] : 'index'),
                              color: Colors.amberAccent,
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProfileScreen(
                                            donorDetails: allDonors[index])),
                                  );
                                },
                                child: ListTile(
                                  leading: Text(
                                    // _foundUsers[index]["id"].toString(),
                                    allDonors.isNotEmpty
                                        ? allDonors[index]["bloodgroup"]
                                        : '$index',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(allDonors[index]['name'],
                                          style: const TextStyle(fontSize: 17)),
                                      Text(
                                          allDonors[index]['mobilenumber']
                                                      .toString() ==
                                                  'null'
                                              ? 'No Number'
                                              : 'Tap for details',
                                          // : allDonors[index]['mobilenumber']
                                          //     .toString(),
                                          style: const TextStyle(fontSize: 15))
                                    ],
                                  ),
                                  subtitle: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          '${allDonors[index]["age"].toString()} years old'),
                                      myLatPosition != null
                                          ? myLatPosition!.latitude != null &&
                                                  myLatPosition!.longitude !=
                                                      null &&
                                                  allDonors[index]
                                                          ['latitude'] !=
                                                      null &&
                                                  allDonors[index]
                                                          ['longitude'] !=
                                                      null
                                              ? (Geolocator.distanceBetween(
                                                                  myLatPosition!
                                                                      .latitude,
                                                                  myLatPosition!
                                                                      .longitude,
                                                                  allDonors[
                                                                          index]
                                                                      [
                                                                      'latitude'],
                                                                  allDonors[
                                                                          index]
                                                                      [
                                                                      'longitude']) /
                                                              1000)
                                                          .toStringAsFixed(2) !=
                                                      '0.00'
                                                  ? Text(
                                                      '${(Geolocator.distanceBetween(myLatPosition!.latitude, myLatPosition!.longitude, allDonors[index]['latitude'], allDonors[index]['longitude']) / 1000).toStringAsFixed(2)}'
                                                      ' km away')
                                                  : Text(
                                                      '${(Geolocator.distanceBetween(myLatPosition!.latitude, myLatPosition!.longitude, allDonors[index]['latitude'], allDonors[index]['longitude'])).toStringAsFixed(2)}'
                                                      ' m near')
                                              : const Text('Not Found')
                                          : const Text('Searching...'),
                                      // Text(
                                      //     '${((random.nextDouble()) * random.nextInt(index + 10)).toStringAsFixed(2)} km away'),
                                      // Geolocator.distanceBetween(myLatPosition!.latitude, myLatPosition!.longitude, allDonors[index]['latitude'], allDonors[index]['longitude']),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                      : Text(
                          sometext!,
                          style: const TextStyle(fontSize: 24),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
