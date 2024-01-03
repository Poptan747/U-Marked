import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:intl/intl.dart';
import 'package:u_marked/models/weekType.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';
import 'package:u_marked/reusable_widget/appBar.dart';

class editClassPage extends StatefulWidget {
  final String documentID;
  const editClassPage({Key? key, required this.documentID}) : super(key: key);

  @override
  State<editClassPage> createState() => _editClassPageState();
}

class _editClassPageState extends State<editClassPage> {
  int _index = 0;
  late Timer _timer;
  List<WeekType> _weekTypeRadio = List.generate(7, (index) => WeekType.allWeek);
  List<bool> _weekdaySwitches = List.generate(7, (index) => false);
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _studentData = [];
  List<Map<String, dynamic>> _subjectData = [];
  List<Map<String, dynamic>> _locationData = [];
  List<Map<String, dynamic>> lecturersInfo = [];
  List<Map<String, dynamic>> studentsInfo = [];
  Set<Map<String, dynamic>> _selectedLec = {};
  Set<Map<String, dynamic>> _selectedStudent = {};
  String selectedSubject = '';
  String selectedLocation = '';
  String? selectedCategory;
  List<TextEditingController> startFromControllers = List.generate(7, (index) => TextEditingController());
  List<TextEditingController> endAtControllers = List.generate(7, (index) => TextEditingController());
  TextEditingController classNameController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchStudentController = TextEditingController();
  final _classForm = GlobalKey<FormState>();
  String _errorMessage = '';
  String _errorLecMessage = '';
  String _errorStudentMessage = '';
  String _errorFinal = '';

  _stepState(int step) {
    if (_index > step) {
      return StepState.editing;
    } else {
      return StepState.indexed;
    }
  }

  @override
  void dispose() {
    for (var controller in startFromControllers) {
      controller.dispose();
    }
    for (var controller in endAtControllers) {
      controller.dispose();
    }
    classNameController.dispose();
    _searchController.dispose();
    _searchStudentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    loadInitialData();
  }

  void loadInitialData() async{
    String classID = widget.documentID;
    var classCollection = await FirebaseFirestore.instance.collection('classes').doc(classID).get();
    var classData = await classCollection.data() as Map<String, dynamic>;
    var locationCollection = await FirebaseFirestore.instance.collection('locations').doc(classData['locationID']).get();
    var locationData = await locationCollection.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> classSessionData = await fetchClassSessionDataFromFirebase();
    setWeekdaySwitches(classSessionData);
    // getSelectedLec(classData);

    setState(() {
      classNameController.text = classData['className'];
      selectedSubject = classData['subjectID'];
      selectedLocation = locationData['roomNo'];
    });
  }

  void getSelectedLec(Map<String, dynamic> classData) async{
    List<String> outputList = classData['lecturerID'].split(',');
    List<String> lecturerNames = [];
    for(var lecID in outputList) {
      String lecDocID = '';
      QuerySnapshot<
          Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('lecturers')
          .where('lecturerID', isEqualTo: lecID)
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
      for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
        lecDocID = document.id;
      }
      var lecturerCollection = await FirebaseFirestore.instance.collection('lecturers').doc(lecDocID).get();
      var lecturerData = await lecturerCollection.data() as Map<String, dynamic>;
      setState(() {
        _selectedLec.add({"lecturerID": lecturerData['lecturerID'], "name": lecturerData['name']});
      });
    }
  }

  void setWeekdaySwitches(List<Map<String, dynamic>> classSessionData) {
    for (int i = 0; i < classSessionData.length; i++) {
      Map<String, dynamic> session = classSessionData[i];
      if (session.containsKey('day')) {
        String day = session['day'];
        int index = _dayToIndex(day);
        if (index != -1) {
          setState(() {
            _weekdaySwitches[index] = true;
            WeekType weekType = WeekType.values.firstWhere(
                  (e) => e.toString().split('.').last == session['weekType'],
            );
            _weekTypeRadio[index] = weekType;
            startFromControllers[index].text = session['startFrom'];
            endAtControllers[index].text = session['endAt'];
          });
        }
      }
    }
  }

  int _dayToIndex(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 0;
      case 'tuesday':
        return 1;
      case 'wednesday':
        return 2;
      case 'thursday':
        return 3;
      case 'friday':
        return 4;
      case 'saturday':
        return 5;
      case 'sunday':
        return 6;
      default:
        return -1; // Indicates an invalid day
    }
  }

  String _day(int index) {
    switch (index) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      case 6:
        return 'Sunday';
      default:
        return '';
    }
  }

  Future<void> _fetchData() async {
    List<Map<String, dynamic>> data = await fetchDataFromFirebase(false);
    List<Map<String, dynamic>> studentData = await fetchDataFromFirebase(true);
    List<Map<String, dynamic>> subjectData = await fetchSubjectDataFromFirebase();
    List<Map<String, dynamic>> locationData = await fetchLocationDataFromFirebase();
    setState(() {
      _data = data;
      _studentData = studentData;
      _subjectData = subjectData;
      _locationData = locationData;
    });
  }

  Future<List<Map<String, dynamic>>> fetchDataFromFirebase(bool isStudent) async {
    if(isStudent){
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('students')
            .get();

        return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      } catch (e) {
        print("Error fetching data from Firebase: $e");
        return [];
      }
    }else{
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('lecturers')
            .get();

        return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      } catch (e) {
        print("Error fetching data from Firebase: $e");
        return [];
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchSubjectDataFromFirebase() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching data from Firebase: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchLocationDataFromFirebase() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching data from Firebase: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchClassSessionDataFromFirebase() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('classes').doc(widget.documentID).collection('classSession')
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching data from Firebase: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> _filteredData(bool isStudent) {
    if(isStudent){
      final String searchTerm = _searchStudentController.text.toLowerCase();
      return _studentData.where((item) {
        return item['batch'].toLowerCase().contains(searchTerm) ||  item['studentID'].toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    }else{
      final String searchTerm = _searchController.text.toLowerCase();
      return _data.where((item) {
        return item['name'].toLowerCase().contains(searchTerm) ||  item['lecturerID'].toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String userId) async {
    try {
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      var userData = await userCollection.data() as Map<String, dynamic>;

      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection(userData['userType'] == 1? 'students' : 'lecturers')
          .doc(userId)
          .get();

      return snapshot.data() ?? {}; // Return an empty map if the user is not found
    } catch (e) {
      print("Error fetching user information: $e");
      return {};
    }
  }

  Future<List<String>> fetchClassMembers(String classId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('members')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error fetching class members: $e");
      return [];
    }
  }

  Future<void> viewAssignedLec() async{
    List<Map<String, dynamic>> updatedLecturersInfo = [];
    var classCollection = await FirebaseFirestore.instance.collection('classes').doc(widget.documentID).get();
    var classData = await classCollection.data() as Map<String, dynamic>;
    List<String> outputList = classData['lecturerID'].split(',');
    for(var lecID in outputList) {
      String lecDocID = '';
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('lecturers')
          .where('lecturerID', isEqualTo: lecID.trim())
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
      for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
        lecDocID = document.id;
      }
      var lecturerCollection = await FirebaseFirestore.instance.collection('lecturers').doc(lecDocID).get();
      var lecturerData = await lecturerCollection.data() as Map<String, dynamic>;
      updatedLecturersInfo.add(lecturerData);
    }
    setState(() {
      lecturersInfo = updatedLecturersInfo;
    });
  }

  Future<void> viewAssignedStudent() async{
    List<Map<String, dynamic>> updatedLecturersInfo = [];
      String userDocID = '';
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('classes').doc(widget.documentID).collection('members')
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
      for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
        userDocID = document.id;
        var userCollection = await FirebaseFirestore.instance.collection('users').doc(userDocID).get();
        var userData = await userCollection.data() as Map<String, dynamic>;
        if(userData['userType'] == 1){
          var studentCollection = await FirebaseFirestore.instance.collection('students').doc(userDocID).get();
          var studentData = await studentCollection.data() as Map<String, dynamic>;
          updatedLecturersInfo.add(studentData);
        }
      }
    setState(() {
      studentsInfo = updatedLecturersInfo;
    });
  }

  void kickMember(String classId, String lecID) async {
    String lecDocID = '';
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
        .collection('lecturers')
        .where('lecturerID', isEqualTo: lecID.trim())
        .get();
    List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
    for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
      lecDocID = document.id;
    }

    var classCollection = await FirebaseFirestore.instance.collection('classes').doc(classId).get();
    var classData = await classCollection.data() as Map<String, dynamic>;
    String classLecID = classData['lecturerID'];
    //set class lecID
    if(classLecID.contains(lecID)){
      String temp = '$lecID, ';
      if(classLecID == lecID){
        classLecID = classLecID.replaceAll(lecID, '').replaceAll(",", "");
      }else{
        classLecID = classLecID.replaceAll(temp, '');
      }
      print(classLecID.trim());
      FirebaseFirestore.instance.collection('classes').doc(classId).update({
        'lecturerID' : classLecID.trim(),
      });
    }
    //delete class member
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('members')
        .doc(lecDocID)
        .delete();

    //delete lec class
    await FirebaseFirestore.instance
        .collection('lecturers')
        .doc(lecDocID)
        .collection('classes')
        .doc(classId)
        .delete();

    Navigator.pop(context);
    assignedLecList();
  }

  void kickStudent(String classId, String studentID) async {
    String studentDocID = '';
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('studentID', isEqualTo: studentID.trim())
        .get();
    List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
    for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
      studentDocID = document.id;
    }

    //delete class member
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('members')
        .doc(studentDocID)
        .delete();

    //delete student class
    await FirebaseFirestore.instance
        .collection('students')
        .doc(studentDocID)
        .collection('classes')
        .doc(classId)
        .delete();

    Navigator.pop(context);
    assignedStudentList();
  }

  void _submit() async{
    setState(() {
      _errorMessage = '';
      _errorLecMessage = '';
      _errorStudentMessage = '';
      _errorFinal = '';
    });
    bool isValid = _classForm.currentState!.validate();
    if(selectedLocation.trim().isEmpty || selectedSubject.trim().isEmpty || _weekdaySwitches.every((bool switchValue) => !switchValue)){
      setState(() {
        _errorMessage = 'Please Complete the Class Information Form';
        isValid = false;
      });
    }
    if(!isValid){
      setState(() {
        _errorMessage = 'Please Complete the Class Information Form';
      });
    }
    print('LEC HERE ${_selectedLec}');
    if(_selectedLec.isEmpty){
      var classCollection = await FirebaseFirestore.instance.collection('classes').doc(widget.documentID).get();
      var classData = await classCollection.data() as Map<String, dynamic>;
      String lec = classData['lecturerID'];
      if(lec.trim().isEmpty){
        setState(() {
          _errorLecMessage = 'Please Assign Lecturer to the Class';
          isValid = false;
        });
      }
    }

    if(!isValid){
      setState(() {
        _errorFinal = 'Please Make Sure All the Steps are Complete';
      });
      return;
    }
    _classForm.currentState!.save();

    //check Class session details
    List<List<String>> classSession = [];
    List<Map<String, dynamic>> listOfMaps = [];
    for (int i = 0; i < _weekdaySwitches.length; i++) {
      Map<String, dynamic> classData = {};
      List<String> daySession = [];
      if (_weekdaySwitches[i]) {
        classData = {
          'day': _day(i),
          'weekType': _weekTypeRadio[i].name,
          'startFrom' : startFromControllers[i].text,
          'endAt' : endAtControllers[i].text
        };
        String detailValue = "${_day(i)} ${_weekTypeRadio[i].name} ${startFromControllers[i].text} - ${endAtControllers[i].text}";
        daySession.add(detailValue);
        listOfMaps.add(classData);
        classSession.add(daySession);
      }
    }
    String lecturerHour;
    lecturerHour = classSession.toString();

    try {
      //get location id
      QuerySnapshot<
          Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('roomNo', isEqualTo: selectedLocation)
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot
          .docs;
      String locationID = '';
      for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
        locationID = document.id;
      }

      List<String> lecturerIDs = _selectedLec.map((lecturer) => lecturer['lecturerID'] as String).toList();
      var classCollection = await FirebaseFirestore.instance.collection('classes').doc(widget.documentID).get();
      var classData = await classCollection.data() as Map<String, dynamic>;
      String classLecIDs = classData['lecturerID'];

      if(classLecIDs.trim().isNotEmpty){
        List<String> outputList = classLecIDs.split(',');
        for(var lecID in outputList){
          lecturerIDs.add(lecID);
        }
      }
      List<String> uniqueList = lecturerIDs.toSet().toList();

      print('CHECK EMPTY ${lecturerIDs.isEmpty}');

      //create class
      FirebaseFirestore.instance.collection('classes').doc(widget.documentID).update({
        'className': classNameController.text,
        'subjectID': selectedSubject,
        'locationID': locationID,
        'lecturerID': lecturerIDs.isEmpty? classData['lecturerID'] : uniqueList.toString().replaceAll('[', '').replaceAll(']', ''),
        'lectureHour': lecturerHour.replaceAll('[', '').replaceAll(']', ''),
        'createAt': DateTime.now(),
      }).then((value) async {
        //storing class session time
        DocumentReference parentDocRef = FirebaseFirestore.instance.collection('classes').doc(widget.documentID);
        CollectionReference nestedCollectionRef = parentDocRef.collection('classSession');
        QuerySnapshot nestedCollectionSnapshot = await nestedCollectionRef.get();
        for (QueryDocumentSnapshot documentSnapshot in nestedCollectionSnapshot.docs) {
          await nestedCollectionRef.doc(documentSnapshot.id).delete();
        }
        for (var map in listOfMaps) {
          DocumentReference classDocument = FirebaseFirestore.instance.collection('classes').doc(widget.documentID);
          classDocument.collection('classSession').add({
            'day': map['day'],
            'weekType': map['weekType'],
            'startFrom': map['startFrom'],
            'endAt': map['endAt']
          });
        }
        //add class to lecturer
        for (var lecturer in _selectedLec) {
          String lecDocID = '';
          QuerySnapshot<
              Map<String, dynamic>> querySnapshot = await FirebaseFirestore
              .instance
              .collection('lecturers')
              .where('lecturerID', isEqualTo: lecturer['lecturerID'])
              .get();
          List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot
              .docs;
          for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
            lecDocID = document.id;
          }
          FirebaseFirestore.instance.collection('lecturers').doc(lecDocID)
              .collection('classes').doc(widget.documentID)
              .set({
            'classID': widget.documentID
          });
          FirebaseFirestore.instance.collection('classes').doc(widget.documentID)
              .collection('members').doc(lecDocID)
              .set({
            'uid': lecDocID
          });
        }
        //add class to student and members
        if(_selectedStudent.isNotEmpty){
          for (var student in _selectedStudent) {
            String studentDocID = '';
            QuerySnapshot<
                Map<String, dynamic>> querySnapshot = await FirebaseFirestore
                .instance
                .collection('students')
                .where('studentID', isEqualTo: student['studentID'])
                .get();
            List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot
                .docs;
            for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
              studentDocID = document.id;
            }
            FirebaseFirestore.instance.collection('classes').doc(widget.documentID)
                .collection('members').doc(studentDocID)
                .set({
              'uid': studentDocID
            });
            FirebaseFirestore.instance.collection('students').doc(studentDocID)
                .collection('classes').doc(widget.documentID)
                .set({
              'classID': widget.documentID
            });
          }
        }
      });

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Class Updated!'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    }on FirebaseAuthException catch(error){
      String? message = error.message;
      var snackBar = SnackBar(
        content: Text(message!),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: editClassAppBar(context),
      body: SafeArea(
          child: Stepper(
            currentStep: _index,
            type: StepperType.vertical,

            onStepCancel: () {
              if (_index > 0) {
                setState(() {
                  _index -= 1;
                });
              }else{
                Navigator.pop(context);
              }
            },
            onStepContinue: () {
              if(_index == 2){
                _submit();
              }else if (_index <= 0) {
                setState(() {
                  _index += 1;
                });
              }else if(_index <= 1){
                setState(() {
                  _index += 1;
                });
              }
            },
            onStepTapped: (int index) {
              setState(() {
                _index = index;
              });
            },
            controlsBuilder: (BuildContext context, ControlsDetails details){
              return Column(
                children: [
                  _errorFinal.trim().isNotEmpty? Text(_errorFinal,style: const TextStyle(color: Colors.red),) : const SizedBox(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      GFButton(
                        onPressed: details.onStepContinue,
                        shape: GFButtonShape.pills,
                        elevation: 2,
                        size: GFSize.MEDIUM,
                        child: Text(_index == 2 ? 'Finish' : 'Next'),
                      ),
                      const SizedBox(width: 5),
                      GFButton(
                        onPressed: _index == 0 ? null : details.onStepCancel,
                        shape: GFButtonShape.pills,
                        elevation: 2,
                        size: GFSize.MEDIUM,
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ],
              );
            },
            steps: <Step>[
              AddClassInfo(),
              AddLecInfo(),
              AddStudentInfo()
            ],
          )
      ),
    );
  }

  Step AddClassInfo(){
    return Step(
      title: const Text('Class info'),
      state: _stepState(0),
      isActive: _index == 0,
      content: Form(
        key: _classForm,
        child: Column(
          children: [
            _errorMessage.trim().isNotEmpty? Text(_errorMessage,style: const TextStyle(color: Colors.red),) : const SizedBox(),
            TextFormField(
              controller: classNameController,
              decoration: const InputDecoration(labelText: 'Class Name'),
              validator: (value){
                if(value == null || value.trim().isEmpty){
                  return 'Please enter class name';
                }
              },
            ),
            DropdownSearch<String>(
              selectedItem: selectedSubject,
              popupProps: const PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
              ),
              items: _subjectData.map((item) => "${item['name']} (${item['subjectID']})").toList(),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Select a Subject",
                  hintText: "Subject Name (Subject Code)",
                ),
              ),
              onChanged: (String? value) {
                RegExp regex = RegExp(r'\((.*?)\)');
                Match? match = regex.firstMatch(value!);
                String? valueInBrackets = match?.group(1);
                setState(() {
                  selectedSubject = valueInBrackets!;
                });
                print(valueInBrackets);
              },
            ),
            DropdownSearch<String>(
              selectedItem: selectedLocation,
              popupProps: const PopupProps.menu(
                  showSelectedItems: true,
                  showSearchBox: true
              ),
              items: _locationData.map((item) => "${item['roomNo']} (${item['building']})").toList(),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Select a Location",
                  hintText: "Room No (Building)",
                ),
              ),
              onChanged: (String? value) {
                int? startIndex = value?.indexOf('(');
                String? roomNo = startIndex != -1 ? value?.substring(0, startIndex).trim() : value?.trim();
                setState(() {
                  selectedLocation = roomNo!;
                });
                print(roomNo);
              },
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: GFColors.LIGHT,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text('Class Session Details'),
                    SizedBox(
                      height: 400,
                      child: ListView.builder(
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                ListTile(
                                  title: Text(_day(index)),
                                  trailing: Switch(
                                    value: _weekdaySwitches[index],
                                    onChanged: (value) {
                                      setState(() {
                                        _weekdaySwitches[index] = value;
                                      });
                                    },
                                  ),
                                ),
                                if (_weekdaySwitches[index]) // Show text fields only when switch is on
                                  Padding(
                                    padding: const EdgeInsets.only(left: 15,right: 15),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Radio(
                                              value: WeekType.allWeek,
                                              groupValue: _weekTypeRadio[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  _weekTypeRadio[index] = value as WeekType;
                                                });
                                              },
                                            ),
                                            const Text('All Week'),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Radio(
                                              value: WeekType.oddWeek,
                                              groupValue: _weekTypeRadio[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  _weekTypeRadio[index] = value as WeekType;
                                                });
                                              },
                                            ),
                                            const Text('Odd Week'),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Radio(
                                              value: WeekType.evenWeek,
                                              groupValue: _weekTypeRadio[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  _weekTypeRadio[index] = value as WeekType;
                                                });
                                              },
                                            ),
                                            Text('Even Week'),
                                          ],
                                        ),
                                        TextFormField(
                                          controller: startFromControllers[index],
                                          decoration: const InputDecoration(labelText: 'Start From'),
                                          readOnly: true,
                                          validator: (value){
                                            if(_weekdaySwitches[index]){
                                              if(value == null || value.trim().isEmpty){
                                                return 'Please select a time';
                                              }
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
                                                startFromControllers[index].text = formattedTime;
                                                endAtControllers[index].text = '';
                                              });
                                            }else{
                                              print("Date is not selected");
                                            }
                                          },
                                        ),
                                        TextFormField(
                                            controller: endAtControllers[index],
                                            decoration: const InputDecoration(labelText: 'End At'),
                                            readOnly: true,
                                            validator: (value){
                                              if(_weekdaySwitches[index]){
                                                if(value == null || value.trim().isEmpty){
                                                  return 'Please select a time';
                                                }
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

                                                if(startFromControllers[index].text.isNotEmpty){
                                                  DateTime startDateTime = DateFormat.jm().parse(startFromControllers[index].text);

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
                                                      endAtControllers[index].text = formattedTime;
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
                                            }
                                        ),
                                      ],
                                    ),
                                  ),
                                const Divider(), // Add a divider for separation
                              ],
                            );
                          }
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Step AddLecInfo(){
    return Step(
        title: const Text('Assign Lecturer to class'),
        subtitle: GestureDetector(
          onTap: () async {
            await viewAssignedLec();
            assignedLecList();
          },
          child: const Row(
            children: [
              Text('View All Assigned Lecturers'),
              Icon(
                Icons.double_arrow_outlined,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        state: _stepState(1),
        isActive: _index == 1,
        content: Form(
          child: Column(
            children: [
              _errorLecMessage.trim().isNotEmpty? Text(_errorLecMessage,style: const TextStyle(color: Colors.red),) : const SizedBox(),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(labelText: 'Search'),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                child: PaginatedDataTable(
                  columns: const [
                    DataColumn(label: Text('Lecturer ID')),
                    DataColumn(label: Text('Name')),
                  ],
                  source: _lecturerPaginatedDataTableSource(
                    data: _filteredData(false),
                    selectedItems: _selectedLec,
                    onSelectChanged: (selected, item) {
                      setState(() {
                        if (selected) {
                          _selectedLec.add(item);
                        } else {
                          _selectedLec.remove(item);
                        }
                        print(_selectedLec);
                      });
                    },
                  ),
                  rowsPerPage: 10,
                ),
              ),
            ],
          ),
        ) // replace Placeholder with solution
    );
  }

  void assignedLecList() async{
    await viewAssignedLec();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assigned Lecturers'),
          content: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  for (var memberInfo in lecturersInfo)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(memberInfo['lecturerID']),
                            ElevatedButton(
                              onPressed: () {
                                kickMember(widget.documentID, memberInfo['lecturerID']);
                              },
                              child: const Text('Unassigned'),
                            ),
                          ],
                        ),
                        const Divider()
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Step AddStudentInfo(){
    return Step(
        title: const Text('Assign Student to class'),
        subtitle: GestureDetector(
          onTap: () async {
            await viewAssignedStudent();
            assignedStudentList();
          },
          child: const Row(
            children: [
              Text('View All Assigned Students'),
              Icon(
                Icons.double_arrow_outlined,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        state: _stepState(2),
        isActive: _index == 2,
        content: Column(
          children: [
            _errorStudentMessage.trim().isNotEmpty? Text(_errorStudentMessage,style: const TextStyle(color: Colors.red),) : const SizedBox(),
            TextField(
              controller: _searchStudentController,
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (value) {
                setState(() {});
              },
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: PaginatedDataTable(
                columns: const [
                  DataColumn(label: Text('Student ID')),
                  DataColumn(label: Text('Batch')),
                ],
                source: _studentPaginatedDataTableSource(
                  data: _filteredData(true),
                  selectedItems: _selectedStudent,
                  onSelectChanged: (selected, item) {
                    setState(() {
                      if (selected) {
                        _selectedStudent.add(item);
                      } else {
                        _selectedStudent.remove(item);
                      }
                      print(_selectedStudent);
                    });
                  },
                ),
                rowsPerPage: 10,
              ),
            ),
          ],
        ) // replace Placeholder with solution
    );
  }

  void assignedStudentList() async{
    await viewAssignedStudent();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assigned Students'),
          content: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  for (var memberInfo in studentsInfo)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(memberInfo['studentID']),
                            ElevatedButton(
                              onPressed: () {
                                kickStudent(widget.documentID, memberInfo['studentID']);
                              },
                              child: const Text('Unassigned'),
                            ),
                          ],
                        ),
                        const Divider()
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _lecturerPaginatedDataTableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final Set<Map<String, dynamic>> selectedItems;
  final Function(bool selected, Map<String, dynamic> item) onSelectChanged;

  _lecturerPaginatedDataTableSource({
    required this.data,
    required this.selectedItems,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final item = data[index];
    final isSelected = selectedItems.contains(item);

    return DataRow.byIndex(
      index: index,
      selected: isSelected,
      onSelectChanged: (selected) => onSelectChanged(selected!, item),
      cells: [
        DataCell(Text(item['lecturerID'].toString())),
        DataCell(Text(item['name'].toString())),
      ],
    );
  }

  @override
  int get rowCount => data.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selectedItems.length;
}

class _studentPaginatedDataTableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final Set<Map<String, dynamic>> selectedItems;
  final Function(bool selected, Map<String, dynamic> item) onSelectChanged;

  _studentPaginatedDataTableSource({
    required this.data,
    required this.selectedItems,
    required this.onSelectChanged,
  });

  @override
  DataRow getRow(int index) {
    final item = data[index];
    final isSelected = selectedItems.contains(item);

    return DataRow.byIndex(
      index: index,
      selected: isSelected,
      onSelectChanged: (selected) => onSelectChanged(selected!, item),
      cells: [
        DataCell(Text(item['studentID'].toString())),
        DataCell(Text(item['batch'].toString())),
      ],
    );
  }

  @override
  int get rowCount => data.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selectedItems.length;
}
