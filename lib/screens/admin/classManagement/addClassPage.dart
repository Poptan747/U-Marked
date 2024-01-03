import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:intl/intl.dart';
import 'package:u_marked/models/weekType.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';
import 'package:u_marked/reusable_widget/appBar.dart';

class addClassPage extends StatefulWidget {
  const addClassPage({Key? key}) : super(key: key);

  @override
  State<addClassPage> createState() => _addClassPageState();
}

class _addClassPageState extends State<addClassPage> {
  int _index = 0;
  List<WeekType> _weekTypeRadio = List.generate(7, (index) => WeekType.allWeek);
  List<bool> _weekdaySwitches = List.generate(7, (index) => false);
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _studentData = [];
  List<Map<String, dynamic>> _subjectData = [];
  List<Map<String, dynamic>> _locationData = [];
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
    // Replace this with your Firebase data fetching logic
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
    if(_selectedLec.isEmpty){
      setState(() {
        _errorLecMessage = 'Please Assign Lecturer to the Class';
        isValid = false;
      });
    }

    if(_selectedStudent.isEmpty){
      setState(() {
        _errorStudentMessage = 'Please Assign Student to the Class';
        isValid = false;
      });
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

      List<String> lecturerIDs = _selectedLec.map((
          lecturer) => lecturer['lecturerID'] as String).toList();

      //create class
      FirebaseFirestore.instance.collection('classes').add({
        'className': classNameController.text,
        'subjectID': selectedSubject,
        'locationID': locationID,
        'lecturerID': lecturerIDs.toString().replaceAll('[', '').replaceAll(
            ']', ''),
        'lectureHour': lecturerHour.replaceAll('[', '').replaceAll(']', ''),
        'createAt': DateTime.now(),
      }).then((value) async {
        //storing class session time
        for (var map in listOfMaps) {
          DocumentReference classDocument = FirebaseFirestore.instance
              .collection('classes').doc(value.id);
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
              .collection('classes').doc(value.id)
              .set({
            'classID': value.id
          });
          FirebaseFirestore.instance.collection('classes').doc(value.id)
              .collection('members').doc(lecDocID)
              .set({
            'uid': lecDocID
          });
        }
        //add class to student and members
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
          FirebaseFirestore.instance.collection('classes').doc(value.id)
              .collection('members').doc(studentDocID)
              .set({
            'uid': studentDocID
          });
          FirebaseFirestore.instance.collection('students').doc(studentDocID)
              .collection('classes').doc(value.id)
              .set({
            'classID': value.id
          });
        }
      });

      Navigator.pop(context);

      var snackBar = const SnackBar(
        content: Text('Class Created!'),
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
      appBar: addClassAppBar(context),
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

  Step AddStudentInfo(){
    return Step(
        title: const Text('Assign Student to class'),
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
