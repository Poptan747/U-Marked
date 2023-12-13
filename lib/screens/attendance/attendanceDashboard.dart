import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/screens/attendance/markedBottomSheet.dart';
import 'package:u_marked/screens/attendance/studentAttendanceList.dart';

class AttendanceDashboard extends StatefulWidget {
  const AttendanceDashboard({Key? key,required this.isStudent, required this.attendanceRecordID}) : super(key: key);
  final String attendanceRecordID;
  final bool isStudent;

  @override
  _AttendanceDashboardState createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> {
  String createdBy = '';
  String geofencingType = '';
  String time = '';
  String date = '';
  String totalAttendanceMember = '';
  int totalMarkedUsers = 0;
  GoogleMapController? mapController;
  late LatLng targetLocation;
  bool locationLoaded = false;
  bool isClose = false;
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

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async{
    String recordID = widget.attendanceRecordID;
    var recordCollection = await FirebaseFirestore.instance.collection('attendanceRecord').doc(recordID).get();
    var recordData = await recordCollection.data() as Map<String, dynamic>;

    var lecCollection = await FirebaseFirestore.instance.collection('lecturers').doc(recordData['createBy']).get();
    var lecData = await lecCollection.data() as Map<String, dynamic>;

    var classCollection = await FirebaseFirestore.instance.collection('classes').doc(recordData['classID']).get();
    var classData = await classCollection.data() as Map<String, dynamic>;

    var locationCollection = await FirebaseFirestore.instance.collection('locations').doc(classData['locationID']).get();
    var locationData = await locationCollection.data() as Map<String, dynamic>;

    var attendanceMember = await FirebaseFirestore.instance
        .collection('attendanceRecord')
        .doc(recordID).collection('studentAttendanceList')
        .get();

    setState(() {
      createdBy = lecData['name'];
      switch (recordData['geofencingType'].toString().trim()) {
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
      if(!isClose){
        List<GeoPoint> newPoints = List<GeoPoint>.from(recordData['polygons']);
        Polygon newPolygon = Polygon(
          polygonId: PolygonId(recordData['geofencingType']),
          points: newPoints.map((point) => LatLng(point.latitude, point.longitude)).toList(),
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
        cameraPoints = newPolygon.points;
        polygons = {newPolygon};
        locationLoaded = true;
      }else{
        // close = true
        List<dynamic> geoPointsData = recordData['polygons'];
        List<LatLng> latLngList = geoPointsData.map((geoPointData) {
          GeoPoint geoPoint = geoPointData;
          targetLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
          return LatLng(geoPoint.latitude, geoPoint.longitude);
        }).toList();
        locationLoaded = true;
      }

      time = '${recordData['startAt']} - ${recordData['endAt']}';
      date = recordData['date'];
      totalAttendanceMember = attendanceMember.size.toString();
      totalMarkedUsers = recordData['markedUser'];
    });
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

  Future<void> getLocation() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    setState(() {
      targetLocation = LatLng(_locationData.latitude!, _locationData.longitude!);
      locationLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: attendanceDashBoardAppBar,
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  locationLoaded ?
                  SizedBox(
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    child: googleMapWidget(),
                  ) : const Center(child: CircularProgressIndicator(),),
                  const SizedBox(height: 10,),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Created By: $createdBy'),
                          const Divider(),
                          Text('Geofencing Type: $geofencingType'),
                          const Divider(),
                          Text('Date: $date'),
                          const Divider(),
                          Text('Time: $time'),
                          const Divider(),
                          Text('Total Present Student: $totalMarkedUsers / $totalAttendanceMember'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40,),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 30,
                    children: [
                      Visibility(
                        visible: !widget.isStudent,
                        child: itemDashboard('Student Attendance', CupertinoIcons.person_crop_circle_fill_badge_checkmark, Colors.deepOrange, 1),
                      ),
                      Visibility(
                        visible: widget.isStudent,
                        child: itemDashboard('Capture Attendances', CupertinoIcons.check_mark_circled, Colors.green, 2),
                      ),

                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  itemDashboard(String title, IconData iconData, Color background , int index) => GestureDetector(
    onTap: (){
      switch (index) {
        case 1:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => studentAttendanceList(isStudent: widget.isStudent,attendanceRecordID: widget.attendanceRecordID),
            ),
          );
          break;
        case 2:
          _showMarkedBottomSheet(context,widget.attendanceRecordID);
        //   Navigator.of(context).push(
        //     MaterialPageRoute(
        //       builder: (context) => attendanceWidget(isStudent: widget.isStudent,classID: widget.classID),
        //     ),
        //   );
          break;
        case 3 :
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => memberList(classID: widget.classID, lecturerID: _lecID),
          //   ),
          // );
          break;
      }
    },
    child: Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                offset: const Offset(0, 5),
                color: Theme.of(context).primaryColor.withOpacity(.2),
                spreadRadius: 2,
                blurRadius: 5
            )
          ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white)
          ),
          const SizedBox(height: 8),
          Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleMedium)
        ],
      ),
    ),
  );

  Widget googleMapWidget() {
    return SizedBox(
      height: 200,
      width: MediaQuery.of(context).size.width,
      child: isClose ?
      GoogleMap(
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
          target: targetLocation,
          zoom: 19.0,
        ),
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
      ) :
      GoogleMap(
          onMapCreated: (controller) {
            setState(() {
              mapController = controller;
              LatLngBounds bounds = getPolygonBounds(cameraPoints);
              LatLng center = LatLng(
                (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
                (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
              );
              CameraPosition cameraPosition = CameraPosition(
                target: center,
                zoom: 18.0, // Adjust the zoom level as needed
              );
              mapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
            });
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(1.5331988034221635, 103.6828984846777),
            zoom: 19.0, // Initial zoom level
          ),
          polygons: polygons
      ),
    );
  }

  void _showMarkedBottomSheet(BuildContext context, String RecordID) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return markedBottomSheet(attendanceRecordID: RecordID); // Display the FormBottomSheet widget
      },
    );
  }
}
