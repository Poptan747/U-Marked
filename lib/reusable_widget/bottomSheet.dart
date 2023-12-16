import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:u_marked/models/userModel.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';
import 'package:u_marked/screens/attendance/attendance.dart';

class FormBottomSheet extends StatefulWidget {
  const FormBottomSheet({Key? key, required this.classID, required this.isStudent}) : super(key: key);
  final String classID;
  final bool isStudent;

  @override
  _FormBottomSheetState createState() => _FormBottomSheetState();
}

class _FormBottomSheetState extends State<FormBottomSheet> {
  final _textEditingController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController startAtTimeController = TextEditingController();
  TextEditingController endAtTimeController = TextEditingController();
  String selectedValue = 'Close';
  GoogleMapController? mapController;
  late LatLng currentLocation;
  bool locationLoaded = false;
  bool isClose = true;
  bool trackAble = false;

  final _form = GlobalKey<FormState>();
  Set<Polygon> currentBuildingPolygons = {
    Polygon(
      polygonId: const PolygonId('Medium'),
      points: const [
        LatLng(1.5342624916037464, 103.68148554209574),
      ],
      strokeWidth: 2,
      strokeColor: Colors.red,
      fillColor: Colors.red.withOpacity(0.3),
    ),
  };
  Set<Polygon> polygons = {
    Polygon(
      polygonId: const PolygonId('Main Building'),
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

  @override
  void dispose() {
    _textEditingController.dispose();
    dateController.dispose();
    startAtTimeController.dispose();
    endAtTimeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
    getLocation();
  }

  void loadData() async{
    DateTime currentDate = DateTime.now();
    String currentDay = DateFormat('EEEE').format(currentDate);
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
        .collection('classes').doc(widget.classID).collection('classSession')
        .where('day', isEqualTo: currentDay)
        .get();
    List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
    if(documents.isNotEmpty){
      for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
        //show modal
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('New Attendance'),
            content: const Text('Looks like you have a class today,\n'
                'do you want to collect attendance based on today class session?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  setText(document);
                  Navigator.pop(context);
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );
      }
    }

    var classCollection = await FirebaseFirestore.instance.collection('classes').doc(widget.classID).get();
    var classData = await classCollection.data() as Map<String, dynamic>;
    var locationCollection = await FirebaseFirestore.instance.collection('locations').doc(classData['locationID']).get();
    var locationData = await locationCollection.data() as Map<String, dynamic>;
    setState(() {
      List<GeoPoint> newPoints = List<GeoPoint>.from(locationData['polygons']);
      Polygon newPolygon = Polygon(
        polygonId: PolygonId('Medium'),
        points: newPoints.map((point) => LatLng(point.latitude, point.longitude)).toList(),
        strokeWidth: 2,
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.3),
      );
      polygons = {newPolygon};
      currentBuildingPolygons = {newPolygon};
      trackAble = locationData['trackAble'];
    });
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
      currentLocation = LatLng(_locationData.latitude!, _locationData.longitude!);
      locationLoaded = true;
    });
  }

  void getCurrentBuildingGeo() async{
    var classCollection = await FirebaseFirestore.instance.collection('classes').doc(widget.classID).get();
    var classData = await classCollection.data() as Map<String, dynamic>;
    var locationCollection = await FirebaseFirestore.instance.collection('locations').doc(classData['locationID']).get();
    var locationData = await locationCollection.data() as Map<String, dynamic>;
    setState(() {
      List<GeoPoint> newPoints = List<GeoPoint>.from(locationData['polygons']);
      Polygon newPolygon = Polygon(
        polygonId: PolygonId('Medium'),
        points: newPoints.map((point) => LatLng(point.latitude, point.longitude)).toList(),
        strokeWidth: 2,
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.3),
      );
      polygons = {newPolygon};
    });
  }

  void setText(DocumentSnapshot<Map<String, dynamic>> document) async{
    final classSessionData = document.data() as Map<String, dynamic>;
    String formattedDate = DateFormat.yMMMEd().format(DateTime.now());
    setState(() {
      dateController.text = formattedDate;
      startAtTimeController.text = classSessionData['startFrom'];
      endAtTimeController.text = classSessionData['endAt'];
    });
  }

  void _submit() async{
    final isValid = _form.currentState!.validate();
    if(!isValid){
      return;
    }
    _form.currentState!.save();

    try{
      var classCollection = await FirebaseFirestore.instance.collection('classes').doc(widget.classID).get();
      var classData = await classCollection.data() as Map<String, dynamic>;
      List<GeoPoint> geoPoints = [];
      if(selectedValue == 'Close'){
        geoPoints.add(GeoPoint(currentLocation.latitude, currentLocation.longitude));
      }else{
        geoPoints = polygons.first.points
            .map((point) => GeoPoint(point.latitude, point.longitude))
            .toList();
      }

      String date = dateController.text;
      FirebaseFirestore.instance.collection('attendanceRecord').add({
        'classID' : widget.classID,
        'startAt' : startAtTimeController.text,
        'endAt' : endAtTimeController.text,
        'date' : date,
        'createBy': FirebaseAuth.instance.currentUser!.uid,
        'geofencingType': selectedValue,
        'polygons': geoPoints,
        'markedUser' : 0,

      }).then((value){
        FirebaseFirestore.instance.collection('classes').doc(widget.classID).collection('attendanceRecord').doc(value.id).set({
          'attendanceRecordID' : value.id,
          'date' : date,
        });
        loadClass(widget.classID,value.id);
      });

      var snackBar = const SnackBar(
        content: Text('Attendance Created!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      _textEditingController.clear();
      dateController.clear();
      startAtTimeController.clear();
      endAtTimeController.clear();

      Navigator.pop(context);
      Navigator.pop(context);

    }on FirebaseFirestore catch(error){
      var snackBar = SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  loadClass(String classID, String recordID) async{
    // final studentCollection = await FirebaseFirestore.instance.collection('classes').doc(classID).collection('members').get();

    try {

      QuerySnapshot<
          Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('classes').doc(classID).collection('members').get();

      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot
          .docs;
      for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
        String userDocID = '';
        userDocID = document.id;
        var userCollection = await FirebaseFirestore.instance.collection('users').doc(userDocID).get();
        var userData = await userCollection.data() as Map<String, dynamic>;

        if (userData['userType'] == 1) {
          print(userData['userType']);
          FirebaseFirestore.instance.collection('attendanceRecord').doc(recordID).collection('studentAttendanceList').add({
            'attendanceRecordID': recordID,
            'studentUID': userDocID,
            'attendanceStatus': 0, //0=pending 1=Present 2=Absent 3=Late 4=Leave early 5=sick
            'attendanceTime': '',
            'notes': '',
          }).then((value) {
            print('THRU HERE STUDENT');
            FirebaseFirestore.instance.collection('students').doc(userDocID).collection('attendanceRecord').doc(recordID).set({
              'attendanceRecordID': recordID,
              'studentAttendanceRecordID': value.id,
              'createAt': DateTime.now()
            }).then((value){
              print('Student insert operation completed successfully');
            });
          });
        }
      }
    }on FirebaseFirestore catch(error){
      print(error);
      var snackBar = SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _form,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Scrollbar(
            scrollbarOrientation: ScrollbarOrientation.right,
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'New Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Attendance Date',icon:Icon(Icons.date_range)),
                    readOnly: true,
                    validator: (value){
                      if(value == null || value.trim().isEmpty){
                        return 'Please select a date';
                      }
                    },
                    onTap: () async{
                      DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(), //get today's date
                          firstDate: DateTime(2000), //DateTime.now() - not to allow to choose before today.
                          lastDate: DateTime(2101)
                      );
                      if(pickedDate != null ){
                        String formattedDate = DateFormat.yMMMEd().format(pickedDate);
                        setState(() {
                          dateController.text = formattedDate;
                        });
                      }else{
                        print("Date is not selected");
                      }
                    },
                  ),
                  TextFormField(
                    controller: startAtTimeController,
                    decoration: const InputDecoration(labelText: 'Start at',icon:Icon(Icons.access_time)),
                    readOnly: true,
                    validator: (value){
                      if(value == null || value.trim().isEmpty){
                        return 'Please select a start at time';
                      }
                    },
                    onTap: () async{
                      DateTime datetime = DateTime.now();
                      var pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: datetime.hour, minute: datetime.minute),
                      );
                      if(pickedTime != null ){
                        DateTime selectedDateTime = DateTime(
                          datetime.year,
                          datetime.month,
                          datetime.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        print(selectedDateTime);
                        String formattedTime = DateFormat.jm().format(selectedDateTime);
                        setState(() {
                          startAtTimeController.text = formattedTime;
                        });
                      }else{
                        print("Date is not selected");
                      }
                    },
                  ),
                  TextFormField(
                    controller: endAtTimeController,
                    decoration: const InputDecoration(labelText: 'End at',icon:Icon(Icons.access_time)),
                    readOnly: true,
                    validator: (value){
                      if(value == null || value.trim().isEmpty){
                        return 'Please select a end at time';
                      }
                    },
                    onTap: () async{
                      DateTime datetime = DateTime.now();
                      var pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: datetime.hour, minute: datetime.minute),
                      );
                      if(pickedTime != null ){
                        DateTime selectedDateTime = DateTime(
                          datetime.year,
                          datetime.month,
                          datetime.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        if(startAtTimeController.text.isNotEmpty){
                          DateTime startDateTime = DateFormat.jm().parse(startAtTimeController.text);

                          DateTime compareStartTime = DateTime(
                            datetime.year,
                            datetime.month,
                            datetime.day,
                            startDateTime.hour,
                            startDateTime.minute
                          );

                          if(selectedDateTime.isAfter(compareStartTime)){
                            String formattedTime = DateFormat.jm().format(selectedDateTime);
                            setState(() {
                              endAtTimeController.text = formattedTime;
                            });
                          } else{
                            Alerts().timePickerAlertDialog(context);
                          }
                        }else{
                          Alerts().startAtFirstAlertDialog(context);
                        }
                      }else{
                        print("Date is not selected");
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  locationLoaded ? googleMapWidget() : const Center(child: CircularProgressIndicator()),
                  DropdownButtonFormField<String>(
                    value: 'Close',
                    decoration: const InputDecoration(
                        labelText: 'Select an GeoFencing option',
                        icon:Icon(Icons.share_location)
                    ),
                    items: trackAble ? const [
                      DropdownMenuItem(
                        value: 'Close',
                        child: Text('Close - Current Location (10 meters)'),
                      ),
                      DropdownMenuItem(
                        value: 'Medium',
                        child: Text('Medium - Building range'),
                      ),
                      DropdownMenuItem(
                        value: 'Large',
                        child: Text('Large - Campus range'),
                      ),
                    ] :
                    const [
                      DropdownMenuItem(
                        value: 'Close',
                        child: Text('Close - Current Location (10 meters)'),
                      )
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value!;
                        if(selectedValue == 'Close'){
                          isClose = true;
                        }else{
                          isClose = false;
                        }
                        updateHighlightedArea();
                      });
                    },
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      String itemName = _textEditingController.text;
                      _submit();
                      // Navigator.pop(context);
                    },
                    child: const Text('Start Capture Attendance'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget googleMapWidget() {
    return SizedBox(
      height: 200,
      width: MediaQuery.of(context).size.width,
      child: isClose ?
      GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        initialCameraPosition: CameraPosition(
          target: currentLocation,
          zoom: 19.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('currentLocation'),
            position: currentLocation,
            infoWindow: const InfoWindow(title: 'Current Location'),
          ),
        },
        circles: {
          Circle(
            circleId: CircleId('radiusCircle'),
            center: currentLocation,
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
            });
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(1.5331988034221635, 103.6828984846777),
            zoom: 15.0, // Initial zoom level
          ),
          polygons: polygons
      ),
    );
  }

  void updateHighlightedArea() {
    setState(() {
      polygons.clear();
      polygons.add(getPolygon(selectedValue));
    });
    fitBounds();
  }

  void fitBounds() {
    LatLngBounds bounds = getPolygonBounds(polygons.first.points);
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
  }

  LatLngBounds getPolygonBounds(List<LatLng> polygonPoints) {
    double minLat = polygonPoints.first.latitude;
    double maxLat = polygonPoints.first.latitude;
    double minLng = polygonPoints.first.longitude;
    double maxLng = polygonPoints.first.longitude;

    for (LatLng point in polygonPoints) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      } else if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      } else if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Polygon getPolygon(String option) {
    switch (option) {
      case 'Medium':
        return currentBuildingPolygons.firstWhere(
              (polygon) => polygon.polygonId.value == option,
          orElse: () => Polygon(polygonId: PolygonId('Default'), points: []),
        );
      case 'Large':
        return Polygon(
          polygonId: PolygonId(option),
          points: const [
            LatLng(1.5332594730194127, 103.6797866407739),
            LatLng(1.5317472482436094, 103.68148179682997),
            LatLng(1.5340852974473582, 103.68373485238267),
            LatLng(1.5355278081800041, 103.68183584842873),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
      default:
      // Use default polygon for 'Other'
        return Polygon(
          polygonId: PolygonId('Close'),
          points: [
            currentLocation
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
    }
  }
}

class createStudentBottomSheet extends StatefulWidget {
  const createStudentBottomSheet({Key? key}) : super(key: key);

  @override
  State<createStudentBottomSheet> createState() => _createStudentBottomSheetState();
}

class _createStudentBottomSheetState extends State<createStudentBottomSheet> {

  final _createStudentForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enteredEmailController = TextEditingController();
  final TextEditingController _enteredPhoneController = TextEditingController();
  final TextEditingController _enteredNameController = TextEditingController();
  final TextEditingController _enteredStudentIDController = TextEditingController();
  final TextEditingController _enteredBatchController = TextEditingController();
  String _errorMessage = '';
  bool isLoading = false;
  File? _pickedImageFile;

  @override
  void dispose() {
    _passwordController.dispose();
    _enteredEmailController.dispose();
    _enteredPhoneController.dispose();
    _enteredStudentIDController.dispose();
    _enteredBatchController.dispose();
    _enteredNameController.dispose();
    super.dispose();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
    });
    final isValid = _createStudentForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createStudentForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });
      var currentUserUid = FirebaseAuth.instance.currentUser!.uid;
      String currentUEmail = FirebaseAuth.instance.currentUser!.email!;
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      var userCredentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _enteredEmailController.text, password: _passwordController.text
      );

      User? user = userCredentials.user;
      if (user != null) {

        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email' : _enteredEmailController.text,
          'password' : _passwordController.text,
          'userType' : 1, //student 1 , lec, 2 , admin 3
          'createAt' : DateTime.now(),
          'phoneNum' : _enteredPhoneController.text,
          'isEmailVerified' : false,
          'isPhoneVerified' : false,
        }).then((value) async {
          if(_pickedImageFile !=null){
            final metadata = SettableMetadata(contentType: "image/jpeg");
            final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${user.uid}.jpg');
            await storageRef.putFile(_pickedImageFile!,metadata);
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'imagePath' :  await storageRef.getDownloadURL(),
            });
          }else{
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'imagePath' :  ''
            });
          }
        }).catchError((error) {
          print(error);
        });

        FirebaseFirestore.instance.collection('students').doc(user.uid).set({
          'batch' : _enteredBatchController.text,
          'name' : _enteredNameController.text,
          'studentID' : _enteredStudentIDController.text,
        }).catchError((error) {
          print(error);
        });

        var _siginAgain = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: currentUEmail, password: data['password']
        );
      }

      setState(() {
        isLoading = false;
      });

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Student account created!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      setState(() {
        _errorMessage = error.message.toString();
      });
    }
  }

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _createStudentForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'New Student',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  foregroundImage: _pickedImageFile!=null? FileImage(_pickedImageFile!) : null,
                  radius: 50,
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add profile picture'),
                ),
                isLoading? const CircularProgressIndicator() : const SizedBox(height: 1),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredStudentIDController,
                  decoration: const InputDecoration(labelText: 'Student ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid student ID';
                    }
                  },
                  onSaved: (value){
                    _enteredStudentIDController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredBatchController,
                  decoration: const InputDecoration(labelText: 'Batch',icon:Icon(Icons.groups_2)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid batch';
                    }
                  },
                  onSaved: (value){
                    _enteredBatchController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredNameController,
                  decoration: const InputDecoration(labelText: 'Name',icon:Icon(Icons.person)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid name';
                    }
                  },
                  onSaved: (value){
                    _enteredNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email',icon:Icon(Icons.email)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || !value.contains('@')){
                      return 'Please enter a valid email address';
                    }
                  },
                  onSaved: (value){
                    _enteredEmailController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number',icon:Icon(Icons.phone), hintText: '+60123456789'),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid phone number';
                    }
                    if(value.contains('-')||value.contains(' ')){
                      return '"-" and empty spaces are not needed.';
                    }
                    if(!value.contains('+')){
                      return 'Please enter the country code with "+".';
                    }
                  },
                  onSaved: (value){
                    _enteredPhoneController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password',icon:Icon(Icons.password)),
                        validator: (value){
                          if(value == null || value.trim().isEmpty){
                            return 'Please enter a password';
                          }
                        },
                        onSaved: (value){
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        setState(() {
                          _passwordController.text = generateRandomString(8);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Create Student Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class editStudentBottomSheet extends StatefulWidget {
  final String uid;
  const editStudentBottomSheet({Key? key,required this.uid}) : super(key: key);

  @override
  State<editStudentBottomSheet> createState() => _editStudentBottomSheetState();
}

class _editStudentBottomSheetState extends State<editStudentBottomSheet> {
  final _editStudentForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enteredEmailController = TextEditingController();
  final TextEditingController _enteredPhoneController = TextEditingController();
  final TextEditingController _enteredNameController = TextEditingController();
  final TextEditingController _enteredStudentIDController = TextEditingController();
  final TextEditingController _enteredBatchController = TextEditingController();
  String _errorMessage = '';
  File? _pickedImageFile;
  String imageUrl ='';
  bool changeImage = false;
  bool isLoading = false;
  bool _isEmailVerify = false;
  bool _isPhoneVerify = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _enteredEmailController.dispose();
    _enteredPhoneController.dispose();
    _enteredStudentIDController.dispose();
    _enteredBatchController.dispose();
    _enteredNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    try {
      String uid = widget.uid;
      var userCollection = await FirebaseFirestore.instance.collection('users')
          .doc(uid)
          .get();
      var data = await userCollection.data() as Map<String, dynamic>;

      UserDetail newUser = UserDetail(
          uid: uid, email: data['email'], userType: data['userType']);
      Map<String, dynamic> userDetailmap = await newUser.getUserDetail();

      setState(() {
        if (data['isEmailVerified']) {
          _isEmailVerify = true;
        }
        if (data['isPhoneVerified']) {
          _isPhoneVerify = true;
        }
        _enteredNameController.text = userDetailmap['name'];
        _enteredStudentIDController.text = userDetailmap['studentID'];
        _enteredBatchController.text = userDetailmap['batch'];
        _enteredEmailController.text = data['email'];
        _enteredPhoneController.text = data['phoneNum'];
        _passwordController.text = data['password'];
        imageUrl = data['imagePath'];
      });
    } on FirebaseException catch(e){
      print(e.message);
    }
  }

  _submit() async{
    bool hasError = false;
    String newEmail='';
    setState(() {
      _errorMessage = '';
    });
    final isValid = _editStudentForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _editStudentForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      if(data['email'] != _enteredEmailController.text){
        List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_enteredEmailController.text);
        if (signInMethods.isEmpty) {
          newEmail = _enteredEmailController.text;
        } else {
          setState(() {
            _errorMessage = 'Email is already in use.';
            hasError = true;
          });
        }
      }else{
        newEmail = data['email'];
      }

      if(!hasError){
        var currentUserUid = FirebaseAuth.instance.currentUser!.uid;
        String currentUEmail = FirebaseAuth.instance.currentUser!.email!;
        var currentUserCollection = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
        var currentUserData = await currentUserCollection.data() as Map<String, dynamic>;

        //change to user
        var _siginAsUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: data['email'], password: data['password']
        );

        await _siginAsUser.user!.updateEmail(newEmail);
        await _siginAsUser.user!.updatePassword(_passwordController.text);

        //change to admin
        var _siginAsAdmin = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: currentUEmail, password: currentUserData['password']
        );

        if(changeImage){
          final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${widget.uid}.jpg');
          if(imageUrl.trim().isNotEmpty){
            await storageRef.delete();
          }
          await storageRef.putFile(_pickedImageFile!);

          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
            'email' : _enteredEmailController.text,
            'password' : _passwordController.text,
            'phoneNum' : _enteredPhoneController.text,
            'imagePath' :  await storageRef.getDownloadURL(),
          }).catchError((error) {
            print(error);
          });
        }else{
          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
            'email' : _enteredEmailController.text,
            'password' : _passwordController.text,
            'phoneNum' : _enteredPhoneController.text,
          }).catchError((error) {
            print(error);
          });
        }

        FirebaseFirestore.instance.collection('students').doc(widget.uid).update({
          'batch' : _enteredBatchController.text,
          'name' : _enteredNameController.text,
          'studentID' : _enteredStudentIDController.text,
        }).catchError((error) {
          print(error);
        });

        Navigator.pop(context);

        var snackBar = const SnackBar(
          content: Text('Student Information changed!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      setState(() {
        isLoading = false;
      });
    }on FirebaseAuthException catch(error){
      setState(() {
        isLoading = false;
        _errorMessage = error.message.toString();
      });
    }
  }

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
      changeImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _editStudentForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'Modify Student Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                changeImage? CircleAvatar(
                  foregroundImage: _pickedImageFile!=null? FileImage(_pickedImageFile!) : null,
                  radius: 50,
                ) :
                imageUrl.trim().isNotEmpty?
                CircleAvatar(
                  foregroundImage: NetworkImage(imageUrl),
                  radius: 50,
                ) :
                const CircleAvatar(
                  foregroundImage: AssetImage('images/user/default_user.jpg'),
                  radius: 50,
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add profile picture'),
                ),
                const SizedBox(height: 10),
                isLoading? const CircularProgressIndicator() : const SizedBox(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GFButton(
                      onPressed: null,
                      color: Colors.black,
                      type: GFButtonType.outline2x,
                      icon: _isEmailVerify? const Icon(Icons.check,color: Colors.green,) :
                      const Icon(Icons.error,color: Colors.red,),
                      text: "Email Verification",
                      size: GFSize.LARGE,
                      shape: GFButtonShape.pills,
                    ),
                    GFButton(
                      onPressed: null,
                      color: Colors.black,
                      type: GFButtonType.outline2x,
                      icon: _isPhoneVerify ? const Icon(Icons.check,color: Colors.green,) :
                      const Icon(Icons.error,color: Colors.red,),
                      text: "Phone Number Verification",
                      size: GFSize.LARGE,
                      shape: GFButtonShape.pills,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredStudentIDController,
                  decoration: const InputDecoration(labelText: 'Student ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid student ID !';
                    }
                  },
                  onSaved: (value){
                    _enteredStudentIDController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredBatchController,
                  decoration: const InputDecoration(labelText: 'Batch',icon:Icon(Icons.groups_2)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid batch !';
                    }
                  },
                  onSaved: (value){
                    _enteredBatchController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredNameController,
                  decoration: const InputDecoration(labelText: 'Name',icon:Icon(Icons.person)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid name !';
                    }
                  },
                  onSaved: (value){
                    _enteredNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredEmailController,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isEmailVerify? true : false,
                  decoration: const InputDecoration(labelText: 'Email',icon:Icon(Icons.email)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || !value.contains('@')){
                      return 'Please enter a valid email address !';
                    }
                  },
                  onSaved: (value){
                    _enteredEmailController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredPhoneController,
                  keyboardType: TextInputType.phone,
                  readOnly: _isPhoneVerify? true : false,
                  decoration: const InputDecoration(labelText: 'Phone Number',icon:Icon(Icons.phone), hintText: '+60123456789'),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid phone number';
                    }
                    if(value.contains('-')||value.contains(' ')){
                      return '"-" and empty spaces are not needed.';
                    }
                    if(!value.contains('+')){
                      return 'Please enter the country code with "+".';
                    }
                  },
                  onSaved: (value){
                    _enteredPhoneController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password',icon:Icon(Icons.password)),
                        validator: (value){
                          if(value == null || value.trim().isEmpty){
                            return 'Please select a date';
                          }
                        },
                        onSaved: (value){
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        setState(() {
                          _passwordController.text = generateRandomString(8);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class createLecturerBottomSheet extends StatefulWidget {
  const createLecturerBottomSheet({Key? key}) : super(key: key);

  @override
  _createLecturerBottomSheetState createState() => _createLecturerBottomSheetState();
}

class _createLecturerBottomSheetState extends State<createLecturerBottomSheet> {

  final _createLecturerForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enteredEmailController = TextEditingController();
  final TextEditingController _enteredPhoneController = TextEditingController();
  final TextEditingController _enteredNameController = TextEditingController();
  final TextEditingController _enteredLecturerIDController = TextEditingController();
  String _errorMessage = '';
  File? _pickedImageFile;

  @override
  void dispose() {
    _passwordController.dispose();
    _enteredEmailController.dispose();
    _enteredPhoneController.dispose();
    _enteredLecturerIDController.dispose();
    _enteredNameController.dispose();
    super.dispose();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
    });
    final isValid = _createLecturerForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createLecturerForm.currentState!.save();

    try{
      var currentUserUid = FirebaseAuth.instance.currentUser!.uid;
      String currentUEmail = FirebaseAuth.instance.currentUser!.email!;
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      var userCredentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _enteredEmailController.text, password: _passwordController.text
      );

      User? user = userCredentials.user;
      if (user != null) {

        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email' : _enteredEmailController.text,
          'password' : _passwordController.text,
          'userType' : 2, //student 1 , lec, 2 , admin 3
          'createAt' : DateTime.now(),
          'phoneNum' : _enteredPhoneController.text,
          'isEmailVerified' : false,
          'isPhoneVerified' : false,
        }).then((value) async {
          if(_pickedImageFile !=null){
            final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${user.uid}.jpg');
            await storageRef.putFile(_pickedImageFile!);
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'imagePath' :  await storageRef.getDownloadURL(),
            });
          }else{
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'imagePath' :  '',
            });
          }
        }).catchError((error) {
          print(error);
        });

        FirebaseFirestore.instance.collection('lecturers').doc(user.uid).set({
          'name' : _enteredNameController.text,
          'lecturerID' : _enteredLecturerIDController.text,
        }).catchError((error) {
          print(error);
        });

        var _siginAgain = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: currentUEmail, password: data['password']
        );
      }

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Lecturer account created!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      setState(() {
        _errorMessage = error.message.toString();
      });
    }
  }

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _createLecturerForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'New Lecturer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  foregroundImage: _pickedImageFile!=null? FileImage(_pickedImageFile!) : null,
                  radius: 50,
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add profile picture'),
                ),
                TextFormField(
                  controller: _enteredLecturerIDController,
                  decoration: const InputDecoration(labelText: 'Lecturer ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid Lecturer ID !';
                    }
                  },
                  onSaved: (value){
                    _enteredLecturerIDController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredNameController,
                  decoration: const InputDecoration(labelText: 'Name',icon:Icon(Icons.person)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid name !';
                    }
                  },
                  onSaved: (value){
                    _enteredNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email',icon:Icon(Icons.email)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || !value.contains('@')){
                      return 'Please enter a valid email address !';
                    }
                  },
                  onSaved: (value){
                    _enteredEmailController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: const TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number',icon:Icon(Icons.phone), hintText: '+60123456789'),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid phone number';
                    }
                    if(value.contains('-')||value.contains(' ')){
                      return '"-" and empty spaces are not needed.';
                    }
                  },
                  onSaved: (value){
                    _enteredPhoneController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password',icon:Icon(Icons.password)),
                        validator: (value){
                          if(value == null || value.trim().isEmpty){
                            return 'Please select a date';
                          }
                        },
                        onSaved: (value){
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        setState(() {
                          _passwordController.text = generateRandomString(8);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Create Lecturer Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class editLecturerBottomSheet extends StatefulWidget {
  final String uid;
  const editLecturerBottomSheet({Key? key,required this.uid}) : super(key: key);

  @override
  State<editLecturerBottomSheet> createState() => _editLecturerBottomSheet();
}

class _editLecturerBottomSheet extends State<editLecturerBottomSheet> {
  final _editLecturerForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enteredEmailController = TextEditingController();
  final TextEditingController _enteredPhoneController = TextEditingController();
  final TextEditingController _enteredNameController = TextEditingController();
  final TextEditingController _enteredLecturerIDController = TextEditingController();
  String _errorMessage = '';
  String imageUrl = '';
  bool changeImage = false;
  File? _pickedImageFile;
  bool isLoading = false; bool _isEmailVerify = false; bool _isPhoneVerify = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _enteredEmailController.dispose();
    _enteredPhoneController.dispose();
    _enteredLecturerIDController.dispose();
    _enteredNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    String uid = widget.uid;
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    UserDetail newUser = UserDetail(uid: uid, email: data['email'], userType: data['userType']);
    Map<String, dynamic> userDetailmap = await newUser.getUserDetail();

    setState(() {
      if (data['isEmailVerified']) {
        _isEmailVerify = true;
      }
      if (data['isPhoneVerified']) {
        _isPhoneVerify = true;
      }
      _enteredNameController.text = userDetailmap['name'];
      _enteredLecturerIDController.text = userDetailmap['lecturerID'];
      _enteredEmailController.text = data['email'];
      _enteredPhoneController.text = data['phoneNum'];
      _passwordController.text = data['password'];
      imageUrl = data['imagePath'];
    });
  }

  _submit() async{
    bool hasError = false;
    String newEmail='';
    setState(() {
      _errorMessage = '';
    });
    final isValid = _editLecturerForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _editLecturerForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      if(data['email'] != _enteredEmailController.text){
        List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_enteredEmailController.text);
        if (signInMethods.isEmpty) {
          newEmail = _enteredEmailController.text;
        } else {
          setState(() {
            _errorMessage = 'Email is already in use.';
            hasError = true;
          });
        }
      }else{
        newEmail = data['email'];
      }

      if(!hasError){
        var currentUserUid = FirebaseAuth.instance.currentUser!.uid;
        String currentUEmail = FirebaseAuth.instance.currentUser!.email!;
        var currentUserCollection = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
        var currentUserData = await currentUserCollection.data() as Map<String, dynamic>;

        //change to user
        var _siginAsUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: data['email'], password: data['password']
        );

        await _siginAsUser.user!.updateEmail(newEmail);
        await _siginAsUser.user!.updatePassword(_passwordController.text);

        //change to admin
        var _siginAsAdmin = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: currentUEmail, password: currentUserData['password']
        );

        if(changeImage){
          final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${widget.uid}.jpg');
          if(imageUrl.trim().isNotEmpty){
            await storageRef.delete();
          }
          await storageRef.putFile(_pickedImageFile!);

          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
            'email' : newEmail,
            'password' : _passwordController.text,
            'phoneNum' : _enteredPhoneController.text,
            'imagePath' : await storageRef.getDownloadURL(),
          }).catchError((error) {
            print(error);
          });
        }else{
          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
            'email' : newEmail,
            'password' : _passwordController.text,
            'phoneNum' : _enteredPhoneController.text,
          }).catchError((error) {
            print(error);
          });
        }

        FirebaseFirestore.instance.collection('lecturers').doc(widget.uid).update({
          'name' : _enteredNameController.text,
          'lecturerID' : _enteredLecturerIDController.text,
        }).catchError((error) {
          print(error);
        });

        Navigator.pop(context);

        var snackBar = const SnackBar(
          content: Text('Lecturer Information changed!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      setState(() {
        isLoading = false;
      });
    }on FirebaseAuthException catch(error){
      setState(() {
        isLoading = false;
        _errorMessage = error.message.toString();
      });
    }
  }

  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      _pickedImageFile = File(pickImage.path);
      changeImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _editLecturerForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'Modify Lecturer Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                changeImage? CircleAvatar(
                  foregroundImage: _pickedImageFile!=null? FileImage(_pickedImageFile!) : null,
                  radius: 50,
                ) :
                    imageUrl.trim().isNotEmpty?
                CircleAvatar(
                  foregroundImage: NetworkImage(imageUrl),
                  radius: 50,
                ) :
                    const CircleAvatar(
                      foregroundImage: AssetImage('images/user/default_user.jpg'),
                      radius: 50,
                    ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add profile picture'),
                ),
                const SizedBox(height: 10),
                isLoading? const CircularProgressIndicator() : const SizedBox(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GFButton(
                      onPressed: null,
                      color: Colors.black,
                      type: GFButtonType.outline2x,
                      icon: _isEmailVerify? const Icon(Icons.check,color: Colors.green,) :
                      const Icon(Icons.error,color: Colors.red,),
                      text: "Email Verification",
                      size: GFSize.LARGE,
                      shape: GFButtonShape.pills,
                    ),
                    GFButton(
                      onPressed: null,
                      color: Colors.black,
                      type: GFButtonType.outline2x,
                      icon: _isPhoneVerify ? const Icon(Icons.check,color: Colors.green,) :
                      const Icon(Icons.error,color: Colors.red,),
                      text: "Phone Number Verification",
                      size: GFSize.LARGE,
                      shape: GFButtonShape.pills,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredLecturerIDController,
                  decoration: const InputDecoration(labelText: 'Lecturer ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid Lecturer ID !';
                    }
                  },
                  onSaved: (value){
                    _enteredLecturerIDController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredNameController,
                  decoration: const InputDecoration(labelText: 'Name',icon:Icon(Icons.person)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid name !';
                    }
                  },
                  onSaved: (value){
                    _enteredNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredEmailController,
                  readOnly: _isEmailVerify? true : false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email',icon:Icon(Icons.email)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || !value.contains('@')){
                      return 'Please enter a valid email address !';
                    }
                  },
                  onSaved: (value){
                    _enteredEmailController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                TextFormField(
                  controller: _enteredPhoneController,
                  keyboardType: TextInputType.phone,
                  readOnly: _isPhoneVerify? true : false,
                  decoration: const InputDecoration(labelText: 'Phone Number',icon:Icon(Icons.phone), hintText: '+60123456789'),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid phone number';
                    }
                    if(value.contains('-')||value.contains(' ')){
                      return '"-" and empty spaces are not needed.';
                    }
                    if(!value.contains('+')){
                      return 'Please enter the country code with "+".';
                    }
                  },
                  onSaved: (value){
                    _enteredPhoneController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password',icon:Icon(Icons.password)),
                        validator: (value){
                          if(value == null || value.trim().isEmpty){
                            return 'Please select a date';
                          }
                        },
                        onSaved: (value){
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {
                        setState(() {
                          _passwordController.text = generateRandomString(8);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class createLocationBottomSheet extends StatefulWidget {
  const createLocationBottomSheet({Key? key}) : super(key: key);

  @override
  _createLocationBottomSheetState createState() => _createLocationBottomSheetState();
}

class _createLocationBottomSheetState extends State<createLocationBottomSheet> {

  final _createLocationForm = GlobalKey<FormState>();
  String _errorMessage = '';
  String selectedOption = 'Option 1';
  bool showOtherInput = false;
  File? _pickedImageFile;
  GoogleMapController? mapController;
  TextEditingController otherInputController = TextEditingController();
  TextEditingController roomNameInputController = TextEditingController();
  TextEditingController roomImageInputController = TextEditingController();
  Set<Polygon> polygons = {
    Polygon(
      polygonId: const PolygonId('Main Building'),
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

  @override
  void dispose() {
    super.dispose();
    roomNameInputController.dispose();
    otherInputController.dispose();
    roomImageInputController.dispose();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
    });
    final isValid = _createLocationForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createLocationForm.currentState!.save();

    try{
      List<GeoPoint> geoPoints = polygons.first.points
          .map((point) => GeoPoint(point.latitude, point.longitude))
          .toList();

      FirebaseFirestore.instance.collection('locations').add({
        'roomNo' : roomNameInputController.text,
        'polygons': geoPoints,
        'building' : selectedOption,
        'trackAble' : !showOtherInput,
      }).then((doc) async {
        final storageRef = FirebaseStorage.instance.ref().child('location_images').child('${doc.id}.jpg');
        await storageRef.putFile(_pickedImageFile!);
        FirebaseFirestore.instance.collection('locations').doc(doc.id).update({
          'imagePath' :  await storageRef.getDownloadURL(),
        });
      });

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Location created!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      setState(() {
        _errorMessage = error.message.toString();
      });
    }
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      roomImageInputController.text = pickImage.path;
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _createLocationForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 10),
                const Text(
                  'New Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _pickedImageFile!= null?
                GFImageOverlay(
                  height: 200,
                  width: 300,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  image: FileImage(_pickedImageFile!),
                ) :
                const SizedBox(height: 10),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) : const SizedBox(height: 10),
                TextFormField(
                  controller: roomImageInputController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Room image',icon: Icon(Icons.image)),
                  onTap: _pickImage,
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please upload a image. ';
                    }
                  },
                  onSaved: (value){
                    // roomNameInputController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: roomNameInputController,
                  decoration: const InputDecoration(labelText: 'Room Name',icon:Icon(Icons.door_front_door)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid room name !';
                    }
                  },
                  onSaved: (value){
                    roomNameInputController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                if(!showOtherInput)SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      setState(() {
                        mapController = controller;
                      });
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(1.5331988034221635, 103.6828984846777), // Initial map center
                      zoom: 15.0, // Initial zoom level
                    ),
                    polygons: polygons
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: 'Main Building',
                  decoration: const InputDecoration(
                    labelText: 'Select a building',
                      icon:Icon(Icons.maps_home_work)
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Main Building',
                      child: Text('Main building'),
                    ),
                    DropdownMenuItem(
                      value: 'IEB',
                      child: Text('IEB'),
                    ),
                    DropdownMenuItem(
                      value: 'TCM',
                      child: Text('TCM'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value == 'Other') {
                        showOtherInput = true;
                      } else {
                        selectedOption = value!;
                        showOtherInput = false;
                        updateHighlightedArea();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (showOtherInput)
                  TextFormField(
                    controller: otherInputController,
                    decoration: const InputDecoration(labelText: "Building Name"),
                    validator: (value){
                      if(showOtherInput = true){
                        if(value == null || value.trim().isEmpty || value.trim().length > 50){
                          return 'Please enter a valid building name !';
                        }
                      }
                    },
                    onSaved: (value){
                      if(showOtherInput = true){
                        selectedOption = value!;
                      }
                    },
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Create new location',style: TextStyle(color: Colors.black),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void updateHighlightedArea() {
    setState(() {
      polygons.clear();
      polygons.add(getPolygon(selectedOption));
    });
    fitBounds();
  }

  void fitBounds() {
    LatLngBounds bounds = getPolygonBounds(polygons.first.points);
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
  }

  LatLngBounds getPolygonBounds(List<LatLng> polygonPoints) {
    double minLat = polygonPoints.first.latitude;
    double maxLat = polygonPoints.first.latitude;
    double minLng = polygonPoints.first.longitude;
    double maxLng = polygonPoints.first.longitude;

    for (LatLng point in polygonPoints) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      } else if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      } else if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Polygon getPolygon(String option) {
    switch (option) {
      case 'TCM':
        return Polygon(
          polygonId: PolygonId(option),
          points: const [
            LatLng(1.5331988034221635, 103.6828984846777),
            LatLng(1.533319427323412, 103.68277217892413),
            LatLng(1.533744429243514, 103.68315899029903),
            LatLng(1.5336283146701633, 103.68329657335201),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
      case 'IEB':
        return Polygon(
          polygonId: PolygonId(option),
          points: const [
            LatLng(1.5350882134102046, 103.68230715997088),
            LatLng(1.5345876809556778, 103.68185606799385),
            LatLng(1.5343982902666615, 103.68208838036203),
            LatLng(1.5348920588136077, 103.68254849417856),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
      case 'Main Building':
        return Polygon(
          polygonId: PolygonId(option),
          points: const [
            LatLng(1.5342624916037464, 103.68148554209574),
            LatLng(1.5340989355078605, 103.68131253961893),
            LatLng(1.5330693361767846, 103.68235860111629),
            LatLng(1.5332395954729914, 103.68252758027968),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
      default:
      // Use default polygon for 'Other'
        return Polygon(
          polygonId: PolygonId('Other'),
          points: [
            LatLng(1.5331988034221635, 103.6828984846777),
            LatLng(1.533319427323412, 103.68277217892413),
            LatLng(1.533744429243514, 103.68315899029903),
            LatLng(1.5336283146701633, 103.68329657335201),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
    }
  }
}

class editLocationBottomSheet extends StatefulWidget {
  final String locationId;
  const editLocationBottomSheet({Key? key,required this.locationId}) : super(key: key);

  @override
  State<editLocationBottomSheet> createState() => _editLocationBottomSheet();
}

class _editLocationBottomSheet extends State<editLocationBottomSheet> {
  final _editLocationForm = GlobalKey<FormState>();
  String _errorMessage = '';
  String selectedOption = 'Option 1';
  bool showOtherInput = false;
  String imageUrl = '';
  File? _pickedImageFile;
  GoogleMapController? mapController;
  TextEditingController otherInputController = TextEditingController();
  TextEditingController roomNameInputController = TextEditingController();
  TextEditingController roomImageInputController = TextEditingController();
  bool isLoading = false;
  Set<Polygon> polygons = {
    Polygon(
      polygonId: const PolygonId('Main Building'),
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

  @override
  void dispose() {
    super.dispose();
    roomNameInputController.dispose();
    otherInputController.dispose();
    roomImageInputController.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    String locationId = widget.locationId;
    var userCollection = await FirebaseFirestore.instance.collection('locations').doc(locationId).get();
    var data = await userCollection.data() as Map<String, dynamic>;
    setState(() {
      roomNameInputController.text = data['roomNo'];
      selectedOption = data['building'];
      imageUrl = data['imagePath'];
      if(selectedOption == 'TCM' || selectedOption == 'IEB' || selectedOption == 'Main Building'){
        showOtherInput = false;
      }else{
        showOtherInput = true;
        otherInputController.text = data['building'];
      }

      List<GeoPoint> newPoints = List<GeoPoint>.from(data['polygons']);
      Polygon newPolygon = Polygon(
        polygonId: PolygonId(data['building']),
        points: newPoints.map((point) => LatLng(point.latitude, point.longitude)).toList(),
        strokeWidth: 2,
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.3),
      );
      polygons = {newPolygon};
    });
  }

  _submit() async{
    bool hasError = false;
    String newEmail='';
    setState(() {
      _errorMessage = '';
    });
    final isValid = _editLocationForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _editLocationForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });
      String locationID = widget.locationId;
      List<GeoPoint> geoPoints = polygons.first.points
          .map((point) => GeoPoint(point.latitude, point.longitude))
          .toList();
      FirebaseFirestore.instance.collection('locations').doc(locationID).update({
        'roomNo' : roomNameInputController.text,
        'polygons': geoPoints,
        'building' : selectedOption,
      }).then((doc) async {
        if(_pickedImageFile!=null){
          final storageRef = FirebaseStorage.instance.ref().child('location_images').child('${locationID}.jpg');
          await storageRef.delete();
          await storageRef.putFile(_pickedImageFile!);
          FirebaseFirestore.instance.collection('locations').doc(locationID).update({
            'imagePath' :  await storageRef.getDownloadURL(),
          });
        }
      });

      setState(() {
        isLoading = false;
      });

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Location information changed!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      setState(() {
        setState(() {
          isLoading = false;
        });
        _errorMessage = error.message.toString();
      });
    }
  }

  void _pickImage() async{
    final pickImage = await ImagePicker().pickImage(source: ImageSource.gallery, maxHeight: 480,
        maxWidth: 640,
        imageQuality: 100);

    if(pickImage == null){
      return;
    }

    setState(() {
      roomImageInputController.text = pickImage.path;
      _pickedImageFile = File(pickImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _editLocationForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  'Edit Location Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _pickedImageFile!= null?
                GFImageOverlay(
                  height: 200,
                  width: 300,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  image: FileImage(_pickedImageFile!),
                ) : imageUrl.trim().isNotEmpty?
                GFImageOverlay(
                  height: 200,
                  width: 300,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  image: NetworkImage(imageUrl),
                ) :
                const CircleAvatar(
                  foregroundImage: AssetImage('images/user/default_user.jpg'),
                  radius: 50,
                ),
                const SizedBox(height: 10),
                isLoading? const CircularProgressIndicator() : const SizedBox(height: 1),
                _errorMessage.trim().isNotEmpty ?
                Text(_errorMessage, style: TextStyle(color: Colors.red),) :
                const SizedBox(height: 10),
                TextFormField(
                  controller: roomImageInputController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Room image',icon: Icon(Icons.image)),
                  onTap: _pickImage,
                  onSaved: (value){
                    // roomNameInputController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: roomNameInputController,
                  decoration: const InputDecoration(labelText: 'Room Name',icon:Icon(Icons.door_front_door)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid room name !';
                    }
                  },
                  onSaved: (value){
                    roomNameInputController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                if(!showOtherInput)SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  child: GoogleMap(
                      onMapCreated: (controller) {
                        setState(() {
                          mapController = controller;
                        });
                      },
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(1.5331988034221635, 103.6828984846777), // Initial map center
                        zoom: 16.0, // Initial zoom level
                      ),
                      polygons: polygons
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedOption == 'TCM' || selectedOption == 'IEB' || selectedOption == 'Main Building'? selectedOption : 'Other',
                  decoration: const InputDecoration(
                      labelText: 'Select a building',
                      icon:Icon(Icons.maps_home_work)
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Main Building',
                      child: Text('Main building'),
                    ),
                    DropdownMenuItem(
                      value: 'IEB',
                      child: Text('IEB'),
                    ),
                    DropdownMenuItem(
                      value: 'TCM',
                      child: Text('TCM'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value == 'Other') {
                        showOtherInput = true;
                      } else {
                        selectedOption = value!;
                        showOtherInput = false;
                        updateHighlightedArea();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (showOtherInput)
                  TextFormField(
                    controller: otherInputController,
                    decoration: const InputDecoration(labelText: 'Building Name'),
                    validator: (value){
                      if(showOtherInput = true){
                        if(value == null || value.trim().isEmpty || value.trim().length > 50){
                          return 'Please enter a valid building name !';
                        }
                      }
                    },
                    onSaved: (value){
                      if(showOtherInput = true){
                        selectedOption = value!;
                      }
                    },
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _submit();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void updateHighlightedArea() {
    setState(() {
      polygons.clear();
      polygons.add(getPolygon(selectedOption));
    });
    fitBounds();
  }

  void fitBounds() {
    LatLngBounds bounds = getPolygonBounds(polygons.first.points);
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
  }

  LatLngBounds getPolygonBounds(List<LatLng> polygonPoints) {
    double minLat = polygonPoints.first.latitude;
    double maxLat = polygonPoints.first.latitude;
    double minLng = polygonPoints.first.longitude;
    double maxLng = polygonPoints.first.longitude;

    for (LatLng point in polygonPoints) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      } else if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      } else if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Polygon getPolygon(String option) {
    switch (option) {
      case 'TCM':
        return Polygon(
          polygonId: PolygonId(option),
          points: const [
            LatLng(1.5331988034221635, 103.6828984846777),
            LatLng(1.533319427323412, 103.68277217892413),
            LatLng(1.533744429243514, 103.68315899029903),
            LatLng(1.5336283146701633, 103.68329657335201),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
      case 'IEB':
        return Polygon(
          polygonId: PolygonId(option),
          points: const [
            LatLng(1.5350882134102046, 103.68230715997088),
            LatLng(1.5345876809556778, 103.68185606799385),
            LatLng(1.5343982902666615, 103.68208838036203),
            LatLng(1.5348920588136077, 103.68254849417856),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
      case 'Main Building':
        return Polygon(
          polygonId: PolygonId(option),
          points: const [
            LatLng(1.5342624916037464, 103.68148554209574),
            LatLng(1.5340989355078605, 103.68131253961893),
            LatLng(1.5330693361767846, 103.68235860111629),
            LatLng(1.5332395954729914, 103.68252758027968),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
      default:
      // Use default polygon for 'Other'
        return Polygon(
          polygonId: PolygonId('Other'),
          points: [
            LatLng(1.5331988034221635, 103.6828984846777),
            LatLng(1.533319427323412, 103.68277217892413),
            LatLng(1.533744429243514, 103.68315899029903),
            LatLng(1.5336283146701633, 103.68329657335201),
          ],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.3),
        );
    }
  }
}

class createSubjectBottomSheet extends StatefulWidget {
  const createSubjectBottomSheet({Key? key}) : super(key: key);

  @override
  State<createSubjectBottomSheet> createState() => _createSubjectBottomSheetState();
}

class _createSubjectBottomSheetState extends State<createSubjectBottomSheet> {

  final _createSubjectForm = GlobalKey<FormState>();
  final TextEditingController _subjectIDController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  String _errorMessage = '';
  bool isLoading = false;

  @override
  void dispose() {
    _subjectIDController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
    });
    final isValid = _createSubjectForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _createSubjectForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });

      String subjectID = _subjectIDController.text;
      String subjectName = _subjectNameController.text;

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('subjectID', isEqualTo: subjectID)
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;

      if(documents.isEmpty){
        FirebaseFirestore.instance.collection('subjects').doc(subjectID).set({
          'name' : subjectName.trim(),
          'subjectID' : subjectID.trim(),
        });
        setState(() {
          Navigator.pop(context);

          var snackBar = const SnackBar(
            content: Text('Subject Created!'),
            behavior: SnackBarBehavior.floating,
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      }else{
        setState(() {
          isLoading = false;
          _errorMessage = 'Subject Already Created!';
          return;
        });
      }

      setState(() {
        isLoading = false;
      });
    }on FirebaseAuthException catch(error){
      setState(() {
        _errorMessage = error.message.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _createSubjectForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'New Subject',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                isLoading? const CircularProgressIndicator() : const SizedBox(),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subjectIDController,
                  decoration: const InputDecoration(labelText: 'Subject ID',icon:Icon(Icons.pin)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid Subject ID';
                    }
                  },
                  onSaved: (value){
                    _subjectIDController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ? Text(_errorMessage, style: const TextStyle(color: Colors.red),) : const SizedBox(),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subjectNameController,
                  decoration: const InputDecoration(labelText: 'Subject Name',icon:Icon(Icons.school)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid Subject Name';
                    }
                  },
                  onSaved: (value){
                    _subjectNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Create New Subject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class editSubjectBottomSheet extends StatefulWidget {
  final String subjectID;
  const editSubjectBottomSheet({Key? key,required this.subjectID}) : super(key: key);

  @override
  State<editSubjectBottomSheet> createState() => _editSubjectBottomSheetState();
}

class _editSubjectBottomSheetState extends State<editSubjectBottomSheet> {
  final _editSubjectForm = GlobalKey<FormState>();
  final TextEditingController _subjectIDController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  String _errorMessage = '';
  bool isLoading = false;

  @override
  void dispose() {
    _subjectIDController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    try {
      String subjectID = widget.subjectID;
      var userCollection = await FirebaseFirestore.instance.collection('subjects')
          .doc(subjectID)
          .get();
      var data = await userCollection.data() as Map<String, dynamic>;

      setState(() {
        _subjectNameController.text = data['name'];
        _subjectIDController.text = data['subjectID'];
      });
    } on FirebaseException catch(e){
      print(e.message);
    }
  }

  _submit() async{
    bool hasError = false;
    setState(() {
      _errorMessage = '';
    });
    final isValid = _editSubjectForm.currentState!.validate();
    if(!isValid){
      return;
    }
    _editSubjectForm.currentState!.save();

    try{
      setState(() {
        isLoading = true;
      });


      String enteredSubjectID = _subjectIDController.text;
      String enteredSubjectName = _subjectNameController.text;

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('subjectID', isEqualTo: enteredSubjectID)
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;

      if(documents.isEmpty){
        hasError = false;
      }else{
        if(enteredSubjectID.trim() == widget.subjectID){
          hasError = false;
        }else{
          hasError = true;
        }
      }

      if(!hasError){
        FirebaseFirestore.instance.collection('subjects').doc(widget.subjectID).delete();
        FirebaseFirestore.instance.collection('subjects').doc(enteredSubjectID).set({
          'name' : enteredSubjectName.trim(),
          'subjectID' : enteredSubjectID.trim(),
        }).then((value) async {
          QuerySnapshot<Map<String, dynamic>> classQuerySnapshot = await FirebaseFirestore.instance
              .collection('classes')
              .where('subjectID', isEqualTo: widget.subjectID)
              .get();
          List<DocumentSnapshot<Map<String, dynamic>>> classDocuments = classQuerySnapshot.docs;
          if(classDocuments.isNotEmpty){
            for (DocumentSnapshot<Map<String, dynamic>> document in documents){
              String classID = document.id;
              FirebaseFirestore.instance.collection('classes').doc(classID).update({
                'subjectID' : enteredSubjectID.trim(),
              });
            }
          }
        });

        setState(() {
          Navigator.pop(context);
          var snackBar = const SnackBar(
            content: Text('Subject Information Changed!'),
            behavior: SnackBarBehavior.floating,
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      }else{
        setState(() {
          isLoading = false;
          _errorMessage = 'Subject Already Created!';
          return;
        });
      }

      setState(() {
        isLoading = false;
      });
    }on FirebaseAuthException catch(error){
      setState(() {
        isLoading = false;
        _errorMessage = error.message.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _editSubjectForm,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Modify Subject Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                isLoading? const CircularProgressIndicator() : const SizedBox(),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subjectIDController,
                  decoration: const InputDecoration(labelText: 'Subject ID',icon:Icon(Icons.badge)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty || value.trim().length > 50){
                      return 'Please enter a valid Subject ID !';
                    }
                  },
                  onSaved: (value){
                    _subjectIDController.text = value!;
                  },
                ),
                _errorMessage.trim().isNotEmpty ? Text(_errorMessage, style: const TextStyle(color: Colors.red),) : const SizedBox(),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subjectNameController,
                  decoration: const InputDecoration(labelText: 'Subject Name',icon:Icon(Icons.groups_2)),
                  validator: (value){
                    if(value == null || value.trim().isEmpty){
                      return 'Please enter a valid Subject Name !';
                    }
                  },
                  onSaved: (value){
                    _subjectNameController.text = value!;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submit();
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}