import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as map_tool;

class markedBottomSheet extends StatefulWidget {
  const markedBottomSheet({Key? key, required this.attendanceRecordID})
      : super(key: key);
  final String attendanceRecordID;

  @override
  State<markedBottomSheet> createState() => _markedBottomSheetState();
}

final _form = GlobalKey<FormState>();

class _markedBottomSheetState extends State<markedBottomSheet> {
  var _date = '';
  var _startTime = '';
  var _endTime = '';
  String geofencingType = '';
  TextEditingController dateController = TextEditingController();
  TextEditingController withinController = TextEditingController();
  TextEditingController startAtTimeController = TextEditingController();
  TextEditingController endAtTimeController = TextEditingController();
  bool locationLoaded = false;
  bool cameraReady = false;
  bool isInSelectedArea = false;
  late GoogleMapController mapController;
  late Position currentPosition;
  late LatLng targetLocation;
  late LatLng cameraLocation;
  late StreamSubscription<Position> _positionStreamSubscription;
  bool isClose = false;
  bool dynamicFieldDone = false;
  Set<Polygon> polygons = {
    Polygon(
      polygonId: const PolygonId('Building'),
      points: const [
        LatLng(1.5342624916037464, 103.68148554209574),
        LatLng(1.5340989355078605, 103.68131253961893),
        LatLng(1.5330693361767846, 103.68235860111629),
        LatLng(1.5332395954729914, 103.68252758027968),
      ],
      strokeWidth: 2,
      strokeColor: Colors.red,
      fillColor: Colors.red.withOpacity(0.3),
    ),
  };
  List<LatLng> cameraPoints = [];
  List<LatLng> polygonPoints = [];
  late List<TextEditingController> controllers;
  late List<bool> switchValues;
  late List<bool> isSwitchDisabled;

  int hoursDifference = 0;
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();
  List<Widget> textFields = [];

  @override
  void initState() {
    super.initState();
    loadData();
    currentPosition = Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 1,
        altitudeAccuracy: 1,
        heading: 1,
        headingAccuracy: 1,
        speed: 1,
        speedAccuracy: 1);
    _initGeolocator();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  loadData() async {
    var studentAttRecordID = '';
    try {
      var attendanceCollection = await FirebaseFirestore.instance
          .collection('attendanceRecord')
          .doc(widget.attendanceRecordID)
          .get();
      var attendanceData = attendanceCollection.data() as Map<String, dynamic>;

      if (attendanceCollection.exists) {
        setState(() {
          switch (attendanceData['geofencingType'].toString().trim()) {
            case 'Close':
              isClose = true;
              geofencingType = 'Close (10 Meters)';
              break;
            case 'Medium':
              geofencingType = 'Within Building';
              break;
            case 'Large':
              geofencingType = 'Within Campus';
              break;
            default:
              geofencingType = 'None';
              break;
          }
          if (!isClose) {
            List<GeoPoint> newPoints =
                List<GeoPoint>.from(attendanceData['polygons']);
            Polygon newPolygon = Polygon(
              polygonId: PolygonId(attendanceData['geofencingType']),
              points: newPoints
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList(),
              strokeWidth: 2,
              strokeColor: Colors.red,
              fillColor: Colors.red.withOpacity(0.3),
            );
            cameraPoints = newPolygon.points;
            polygonPoints = newPolygon.points;
            polygons = {newPolygon};
            locationLoaded = true;
          } else {
            // close = true
            List<dynamic> geoPointsData = attendanceData['polygons'];
            List<LatLng> latLngList = geoPointsData.map((geoPointData) {
              GeoPoint geoPoint = geoPointData;
              targetLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
              return LatLng(geoPoint.latitude, geoPoint.longitude);
            }).toList();
            locationLoaded = true;
          }
          _date = attendanceData['date'];
          dateController.text = attendanceData['date'];
          _startTime = attendanceData['startAt'];
          startAtTimeController.text = attendanceData['startAt'];
          _endTime = attendanceData['endAt'];
          endAtTimeController.text = attendanceData['endAt'];

          startTime = convertStringToDateTime(attendanceData['startAt']);
          endTime = convertStringToDateTime(attendanceData['endAt']);
          hoursDifference = calculateHoursDifference(startTime, endTime);

          if (hoursDifference <= 1) {
            List<bool> switchValues = List.generate(1, (index) => false);
            List<bool> isSwitchDisabled = List.generate(1, (index) => false);
            List<DateTime> fiedStartTime =
                List.generate(1, (index) => DateTime.now());
            List<DateTime> fiedEndTime =
                List.generate(1, (index) => DateTime.now());
            controllers = List.generate(1, (index) => TextEditingController());

            textFields.add(
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: [
                      const Divider(),
                      TextFormField(
                        readOnly: true,
                        controller: controllers[0],
                        decoration: const InputDecoration(
                          labelText: 'Attendance Session',
                          icon: Icon(Icons.access_time_outlined),
                          border: InputBorder.none,
                        ),
                      ),
                      ListTile(
                        title: const Text('Present'),
                        trailing: Switch(
                          value: switchValues[0],
                          onChanged: isSwitchDisabled[0] || !isInSelectedArea
                              ? null // Disable the switch isSwitchDisabled[i] && !isInSelectedArea
                              : (value) {
                                  setState(() {
                                    switchValues[0] = value;
                                  });
                                },
                        ),
                      ),
                      ElevatedButton(
                          onPressed: isSwitchDisabled[0] || !isInSelectedArea
                              ? null
                              : () {
                                  _submit(0, fiedStartTime[0], fiedEndTime[0],
                                      switchValues[0]);
                                },
                          child: const Text('Capture Attendance'))
                    ],
                  );
                },
              ),
            );

            fiedStartTime[0] = startTime;
            fiedEndTime[0] = endTime;
            controllers[0].text =
                '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
          }
          else {
            List<bool> switchValues =
                List.generate(hoursDifference, (index) => false);
            List<bool> isSwitchDisabled =
                List.generate(hoursDifference, (index) => false);
            List<DateTime> fiedStartTime =
                List.generate(hoursDifference, (index) => DateTime.now());
            List<DateTime> fiedEndTime =
                List.generate(hoursDifference, (index) => DateTime.now());
            controllers = List.generate(
                hoursDifference, (index) => TextEditingController());
            String remainingTime = '';
            String formattedEndTime = '';
            String formattedRemTime = '';

            for (int i = 0; i < hoursDifference; i++) {
              DateTime endTimeForTextField =
                  startTime.add(Duration(hours: i + 1));
              formattedEndTime =
                  DateFormat('h:mm a').format(endTimeForTextField);
              DateTime remainTimeForTextField =
                  startTime.add(Duration(hours: i));
              formattedRemTime =
                  DateFormat('h:mm a').format(remainTimeForTextField);

              textFields.add(
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      children: [
                        const Divider(),
                        TextFormField(
                          readOnly: true,
                          controller: controllers[i],
                          decoration: const InputDecoration(
                            labelText: 'Attendance Session',
                            icon: Icon(Icons.access_time_outlined),
                            border: InputBorder.none,
                          ),
                        ),
                        ListTile(
                          title: const Text('Present'),
                          trailing: Switch(
                            value: switchValues[i],
                            onChanged: isSwitchDisabled[i] || !isInSelectedArea
                                ? null // Disable the switch isSwitchDisabled[i] && !isInSelectedArea
                                : (value) {
                                    setState(() {
                                      switchValues[i] = value;
                                    });
                                  },
                          ),
                        ),
                        ElevatedButton(
                            onPressed: isSwitchDisabled[i] || !isInSelectedArea
                                ? null
                                : () {
                                    _submit(i, fiedStartTime[i], fiedEndTime[i],
                                        switchValues[i]);
                                  },
                            child: const Text('Capture Attendance'))
                      ],
                    );
                  },
                ),
              );

              DateTime currentTime = DateTime.now();
              //startTime.add(Duration(hours: i + 1))

              if (i == 0) {
                fiedStartTime[i] = startTime;
                fiedEndTime[i] = startTime.add(Duration(hours: 1));
                isSwitchDisabled[i] = currentTime.isBefore(startTime) ||
                    currentTime.isAfter(startTime.add(Duration(hours: 1)));
                controllers[i].text =
                    '${DateFormat('h:mm a').format(startTime)} - $formattedEndTime';
              } else if (i == hoursDifference - 1) {
                // Last loop
                if (hoursDifference == 2) {
                  fiedStartTime[i] = remainTimeForTextField;
                  fiedEndTime[i] = endTimeForTextField;
                  isSwitchDisabled[i] =
                      currentTime.isBefore(remainTimeForTextField) ||
                          currentTime.isAfter(endTimeForTextField);
                  controllers[i].text = '$formattedRemTime - $formattedEndTime';
                } else {
                  fiedStartTime[i] = endTimeForTextField;
                  fiedEndTime[i] = endTimeForTextField;
                  isSwitchDisabled[i] =
                      currentTime.isBefore(endTimeForTextField) ||
                          currentTime.isAfter(endTimeForTextField);
                  controllers[i].text = '$remainingTime - $formattedEndTime';
                }
              } else {
                fiedStartTime[i] = remainTimeForTextField;
                fiedEndTime[i] = endTimeForTextField;
                isSwitchDisabled[i] =
                    currentTime.isBefore(remainTimeForTextField) ||
                        currentTime.isAfter(endTimeForTextField);
                controllers[i].text = '$formattedRemTime - $formattedEndTime';
                remainingTime = formattedEndTime;
              }
            }
          }
        });
      }
    } on FirebaseFirestore catch (error) {
      print(error);
      var snackBar = SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  DateTime convertStringToDateTime(String timeString) {
    // Convert the string to a DateTime object
    DateTime parsedTime = DateFormat.jm().parse(timeString);

    // Create a DateTime object with the current date and the parsed time
    DateTime dateTime = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, parsedTime.hour, parsedTime.minute);

    return dateTime;
  }

  int calculateHoursDifference(DateTime startTime, DateTime endTime) {
    Duration difference = endTime.difference(startTime);
    int hoursDifference = difference.inHours;

    return hoursDifference;
  }

  void _initGeolocator() {
    _determinePosition();
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1,
    );
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) {
      setState(() {
        cameraLocation = LatLng(position.latitude, position.longitude);
        cameraReady = true;
        checkUpdatedLocation(LatLng(position.latitude, position.longitude));
        currentPosition = position;
      });
      print(currentPosition);
    }, onError: (dynamic error) {
      print('Location error: $error');
    });
    print(currentPosition);
  }

  _determinePosition() async {
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
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
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
  }

  void checkUpdatedLocation(LatLng pointLatLng) {
    var currentLocationPointFromToolkit =
        map_tool.LatLng(pointLatLng.latitude, pointLatLng.longitude);

    setState(() {
      if (isClose) {
        var targetArea =
            map_tool.LatLng(targetLocation.latitude, targetLocation.longitude);
        if (map_tool.SphericalUtil.computeDistanceBetween(
                currentLocationPointFromToolkit, targetArea) <
            10) {
          // in 10 meters
          isInSelectedArea = true;
        } else {
          isInSelectedArea = false;
        }
      } else {
        List<map_tool.LatLng> maptoolList = [];
        for (var polygon in polygonPoints) {
          maptoolList.add(map_tool.LatLng(polygon.latitude, polygon.longitude));
        }
        isInSelectedArea = map_tool.PolygonUtil.containsLocation(
            currentLocationPointFromToolkit, maptoolList, false);
      }

      if (isInSelectedArea) {
        withinController.text = 'Within Area';
      } else {
        withinController.text = 'Not Within Area';
      }
      print(isInSelectedArea);
    });
  }

  void _submit(int index, DateTime fieldStartTime, DateTime fieldEndTime,
      bool switchValues) async {
    String recordID = widget.attendanceRecordID;
    String userID = FirebaseAuth.instance.currentUser!.uid;
    String studentAttListID = '';

    try {
      var recordCollection = await FirebaseFirestore.instance
          .collection('attendanceRecord')
          .doc(recordID)
          .get();
      var recordData = await recordCollection.data() as Map<String, dynamic>;
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('attendanceRecord')
              .doc(recordID)
              .collection('studentAttendanceList')
              .where('studentUID', isEqualTo: userID)
              .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents =
          querySnapshot.docs;
      if (documents.isNotEmpty) {
        for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
          studentAttListID = document.id;
        }

        DateTime startTime = convertStringToDateTime(recordData['startAt']);
        DateTime endTime = convertStringToDateTime(recordData['endAt']);
        bool studentAttendanceSessionStatus = switchValues;
        String attendanceSession = controllers[index].text;
        int hoursDifferenceSubmit =
            calculateHoursDifference(startTime, endTime);

        //0=pending 1=Present 2=Absent 3=Late 4=Leave early 5=sick
        if (index == 0) {
          //first
          //check if already captured
          QuerySnapshot<Map<String, dynamic>> attListQuerySnapshot =
              await FirebaseFirestore.instance
                  .collection('attendanceRecord')
                  .doc(recordID)
                  .collection('studentAttendanceList')
                  .doc(studentAttListID)
                  .collection('studentAttendanceSession')
                  .where('startAt',
                      isEqualTo: DateFormat.jm().format(fieldStartTime))
                  .get();
          List<DocumentSnapshot<Map<String, dynamic>>> attListDocuments =
              attListQuerySnapshot.docs;
          bool docFounded = false;
          if (attListDocuments.isEmpty) {
            docFounded = false;
          } else {
            docFounded = true;
          }

          if (!docFounded) {
            if (fieldStartTime == startTime) {
              //Present
              FirebaseFirestore.instance
                  .collection('attendanceRecord')
                  .doc(recordID)
                  .collection('studentAttendanceList')
                  .doc(studentAttListID)
                  .collection('studentAttendanceSession')
                  .add({
                'recordID': recordID,
                'studentID': userID,
                'attendanceSession': attendanceSession,
                'startAt': DateFormat.jm().format(startTime),
                'endAt': DateFormat.jm().format(endTime),
                'attendanceStatus':
                    studentAttendanceSessionStatus ? 'Present' : 'Absent',
                'createAt': DateTime.now()
              }).then((value) {
                if(hoursDifferenceSubmit <= 1){
                  FirebaseFirestore.instance
                      .collection('attendanceRecord')
                      .doc(recordID)
                      .collection('studentAttendanceList')
                      .doc(studentAttListID)
                      .update({'attendanceStatus': 1});
                  FirebaseFirestore.instance
                      .collection('attendanceRecord')
                      .doc(recordID)
                      .update({
                    'markedUser': recordData['markedUser'] + 1,
                  });
                }
              });
            }
          } else {
            setState(() {
              var snackBar = const SnackBar(
                content: Text('Attendance Session Already Saved!'),
                behavior: SnackBarBehavior.floating,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            });
            return;
          }
        } else if (index == hoursDifferenceSubmit - 1) {
          QuerySnapshot<Map<String, dynamic>> checkAttListQuerySnapshot =
              await FirebaseFirestore.instance
                  .collection('attendanceRecord')
                  .doc(recordID)
                  .collection('studentAttendanceList')
                  .doc(studentAttListID)
                  .collection('studentAttendanceSession')
                  .where('endAt',
                      isEqualTo: DateFormat.jm().format(fieldEndTime))
                  .get();
          List<DocumentSnapshot<Map<String, dynamic>>> checkAttListDocuments =
              checkAttListQuerySnapshot.docs;
          bool docFounded = false;
          if (checkAttListDocuments.isEmpty) {
            docFounded = false;
          } else {
            docFounded = true;
          }
          //last
          if (!docFounded) {
            if (fieldEndTime == endTime) {
              //check previous record
              QuerySnapshot<Map<String, dynamic>> attListQuerySnapshot =
                  await FirebaseFirestore.instance
                      .collection('attendanceRecord')
                      .doc(recordID)
                      .collection('studentAttendanceList')
                      .doc(studentAttListID)
                      .collection('studentAttendanceSession')
                      .get();
              List<DocumentSnapshot<Map<String, dynamic>>> attListDocuments =
                  attListQuerySnapshot.docs;
              if (attListDocuments.length == hoursDifference - 1) {
                //all record saved = Present
                FirebaseFirestore.instance
                    .collection('attendanceRecord')
                    .doc(recordID)
                    .collection('studentAttendanceList')
                    .doc(studentAttListID)
                    .collection('studentAttendanceSession')
                    .add({
                  'recordID': recordID,
                  'studentID': userID,
                  'attendanceSession': attendanceSession,
                  'startAt': DateFormat.jm().format(fieldStartTime),
                  'endAt': DateFormat.jm().format(fieldEndTime),
                  'attendanceStatus':
                      studentAttendanceSessionStatus ? 'Present' : 'Absent',
                  'createAt': DateTime.now()
                }).then((value) {
                  FirebaseFirestore.instance
                      .collection('attendanceRecord')
                      .doc(recordID)
                      .collection('studentAttendanceList')
                      .doc(studentAttListID)
                      .update({'attendanceStatus': 1});
                  FirebaseFirestore.instance
                      .collection('attendanceRecord')
                      .doc(recordID)
                      .update({
                    'markedUser': recordData['markedUser'] + 1,
                  });
                });
              } else {
                //late
                FirebaseFirestore.instance
                    .collection('attendanceRecord')
                    .doc(recordID)
                    .collection('studentAttendanceList')
                    .doc(studentAttListID)
                    .collection('studentAttendanceSession')
                    .add({
                  'recordID': recordID,
                  'studentID': userID,
                  'attendanceSession': attendanceSession,
                  'startAt': DateFormat.jm().format(fieldStartTime),
                  'endAt': DateFormat.jm().format(fieldEndTime),
                  'attendanceStatus':
                      studentAttendanceSessionStatus ? 'Present' : 'Absent',
                  'createAt': DateTime.now()
                }).then((value) {
                  FirebaseFirestore.instance
                      .collection('attendanceRecord')
                      .doc(recordID)
                      .collection('studentAttendanceList')
                      .doc(studentAttListID)
                      .update({'attendanceStatus': 3});
                });
              }
            }
          } else {
            setState(() {
              var snackBar = const SnackBar(
                content: Text('Attendance Session Already Saved!'),
                behavior: SnackBarBehavior.floating,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            });
            return;
          }
        } else {
          // remaining
          QuerySnapshot<Map<String, dynamic>> checkAttListQuerySnapshot =
              await FirebaseFirestore.instance
                  .collection('attendanceRecord')
                  .doc(recordID)
                  .collection('studentAttendanceList')
                  .doc(studentAttListID)
                  .collection('studentAttendanceSession')
                  .where('startAt',
                      isEqualTo: DateFormat.jm().format(fieldStartTime))
                  .get();
          List<DocumentSnapshot<Map<String, dynamic>>> checkAttListDocuments =
              checkAttListQuerySnapshot.docs;
          bool docFounded = false;
          if (checkAttListDocuments.isEmpty) {
            docFounded = false;
          } else {
            docFounded = true;
          }
          //check if late
          QuerySnapshot<Map<String, dynamic>> attListQuerySnapshot =
              await FirebaseFirestore.instance
                  .collection('attendanceRecord')
                  .doc(recordID)
                  .collection('studentAttendanceList')
                  .doc(studentAttListID)
                  .collection('studentAttendanceSession')
                  .where('startAt',
                      isEqualTo: DateFormat.jm().format(startTime))
                  .get();
          List<DocumentSnapshot<Map<String, dynamic>>> attListDocuments =
              attListQuerySnapshot.docs;

          if (!docFounded) {
            if (attListDocuments.isEmpty) {
              //late
              FirebaseFirestore.instance
                  .collection('attendanceRecord')
                  .doc(recordID)
                  .collection('studentAttendanceList')
                  .doc(studentAttListID)
                  .collection('studentAttendanceSession')
                  .add({
                'recordID': recordID,
                'studentID': userID,
                'attendanceSession': attendanceSession,
                'startAt': DateFormat.jm().format(fieldStartTime),
                'endAt': DateFormat.jm().format(fieldEndTime),
                'attendanceStatus':
                    studentAttendanceSessionStatus ? 'Present' : 'Absent',
                'createAt': DateTime.now()
              }).then((value) {
                FirebaseFirestore.instance
                    .collection('attendanceRecord')
                    .doc(recordID)
                    .collection('studentAttendanceList')
                    .doc(studentAttListID)
                    .update({'attendanceStatus': 3});
              });
            } else {
              //not late
              FirebaseFirestore.instance
                  .collection('attendanceRecord')
                  .doc(recordID)
                  .collection('studentAttendanceList')
                  .doc(studentAttListID)
                  .collection('studentAttendanceSession')
                  .add({
                'recordID': recordID,
                'studentID': userID,
                'attendanceSession': attendanceSession,
                'startAt': DateFormat.jm().format(fieldStartTime),
                'endAt': DateFormat.jm().format(fieldEndTime),
                'attendanceStatus':
                    studentAttendanceSessionStatus ? 'Present' : 'Absent',
                'createAt': DateTime.now()
              });
            }
          } else {
            setState(() {
              var snackBar = const SnackBar(
                content: Text('Attendance Session Already Saved!'),
                behavior: SnackBarBehavior.floating,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            });
            return;
          }
        }
      }

      setState(() {
        var snackBar = const SnackBar(
          content: Text('Attendance Session Saved!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    } on FirebaseFirestore catch (error) {
      var snackBar = SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Capture Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  locationLoaded && cameraReady
                      ? SizedBox(
                          height: 200,
                          width: MediaQuery.of(context).size.width,
                          child: googleMapWidget(),
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                  TextFormField(
                    controller: withinController,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isInSelectedArea ? Colors.green : Colors.red,
                    ),
                    decoration: const InputDecoration(
                        labelText: 'Within Area',
                        icon: Icon(Icons.location_on_outlined),
                        border: InputBorder.none),
                    readOnly: true,
                  ),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(
                        labelText: 'Attendance Date',
                        icon: Icon(Icons.date_range),
                        border: InputBorder.none),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please select a date';
                      }
                    },
                    onTap: () {
                      print(widget.attendanceRecordID);
                    },
                  ),
                  Column(
                    children: textFields,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget dynamicTextField() {
    return ListView.builder(
      itemCount: hoursDifference,
      itemBuilder: (context, index) {
        // Calculate the current time for the text field based on the index
        DateTime startTimeForTextField = startTime.add(Duration(hours: index));
        DateTime endTimeForTextField =
            startTime.add(Duration(hours: index + 1));

        // Format the time in the desired format
        String formattedStartTime =
            DateFormat.jm().format(startTimeForTextField);
        String formattedEndTime = DateFormat.jm().format(endTimeForTextField);

        // Set the text field value as a formatted time range
        String textFieldValue = '$formattedStartTime - $formattedEndTime';

        // For the last text field, use the lastStartTime and endTime
        if (index == hoursDifference - 1) {
          formattedEndTime = DateFormat.jm().format(endTime);
          textFieldValue = '$formattedStartTime - $formattedEndTime';
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: controllers[index],
            decoration: InputDecoration(
              labelText: 'Text Field ${index + 1}',
            ),
            readOnly: true,
            onTap: () {
              // You can add onTap logic here
            },
          ),
        );
      },
    );
  }

  Widget googleMapWidget() {
    return SizedBox(
      height: 200,
      width: MediaQuery.of(context).size.width,
      child: isClose
          ? GoogleMap(
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                setState(() {
                  mapController = controller;
                });
              },
              initialCameraPosition: CameraPosition(
                target: cameraLocation,
                zoom: 19.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: cameraLocation,
                  infoWindow: const InfoWindow(title: 'Current Location'),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('radiusCircle'),
                  center: targetLocation,
                  radius: isClose ? 10 : 0, // in meters
                  strokeWidth: 2,
                  strokeColor: Colors.red,
                  fillColor: Colors.red.withOpacity(0.2),
                ),
              },
            )
          : GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  mapController = controller;
                  LatLngBounds bounds = getPolygonBounds(cameraPoints);
                  LatLng center = LatLng(
                    (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
                    (bounds.southwest.longitude + bounds.northeast.longitude) /
                        2,
                  );
                  CameraPosition cameraPosition = CameraPosition(
                    target: cameraLocation,
                    zoom: 18.0, // Adjust the zoom level as needed
                  );
                  mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(cameraPosition));
                });
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(1.5331988034221635, 103.6828984846777),
                zoom: 19.0, // Initial zoom level
              ),
              polygons: polygons,
              markers: {
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: cameraLocation,
                  infoWindow: const InfoWindow(title: 'Current Location'),
                ),
              },
            ),
    );
  }

  LatLngBounds getPolygonBounds(List<LatLng> points) {
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (LatLng point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
