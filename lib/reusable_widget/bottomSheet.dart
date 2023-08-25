import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:u_marked/reusable_widget/alertDialog.dart';

class FormBottomSheet extends StatefulWidget {
  const FormBottomSheet({Key? key, required this.classID}) : super(key: key);
  final String classID;

  @override
  _FormBottomSheetState createState() => _FormBottomSheetState();
}

class _FormBottomSheetState extends State<FormBottomSheet> {
  final _textEditingController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController startAtTimeController = TextEditingController();
  TextEditingController endAtTimeController = TextEditingController();
  String selectedValue = 'Option 1';
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _textEditingController.dispose();
    dateController.dispose();
    startAtTimeController.dispose();
    endAtTimeController.dispose();
    super.dispose();
  }

  void _submit() async{
    final isValid = _form.currentState!.validate();
    if(!isValid){
      return;
    }
    _form.currentState!.save();

    try{
      var attendanceRecord =
      FirebaseFirestore.instance.collection('attendanceRecord').add({
        'classID' : widget.classID,
        'startAt' : startAtTimeController.text,
        'endAt' : endAtTimeController.text,
        'date' : dateController.text,
        'createBy': FirebaseAuth.instance.currentUser!.uid,
        'attendanceType': 1,
        'geofencingRange': selectedValue,
        'markedUser' : 0,

      }).then((value){
        FirebaseFirestore.instance.collection('classes').doc(widget.classID).collection('attendanceRecord').doc(value.id).set({
          'attendanceRecordID' : value.id
        });
        loadClass(widget.classID,value.id);
      });

      var snackBar = const SnackBar(
        content: Text('Done'),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      _textEditingController.clear();
      dateController.clear();
      startAtTimeController.clear();
      endAtTimeController.clear();

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
    final studentCollection = await FirebaseFirestore.instance.collection('classes').doc(classID).collection('members').get();
    for (var doc in studentCollection.docs) {
      var studentData = doc.data() as Map<String, dynamic>;
      var studentUID = studentData['uid'];
      FirebaseFirestore.instance.collection('attendanceRecord').doc(recordID).collection('studentAttendanceList').add({
        'attendanceRecordID' : recordID,
        'studentUID' : studentUID,
        'attendanceStatus' : 0, //0=pending 1=Present 2=Absent 3=Late 4=Leave early 5=sick
        'attendanceTime' : '',
        'notes': '',
      }).then((value){
        FirebaseFirestore.instance.collection('students').doc(studentUID).collection('attendanceRecord').doc(recordID).set({
          'attendanceRecordID' : recordID,
          'studentAttendanceRecordID' : value.id
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Padding(
        padding: EdgeInsets.all(16.0),
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
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedValue,
              icon: Icon(Icons.share_location),
              onChanged: (newValue) {
                print(newValue);
                setState(() {
                  selectedValue = newValue!;
                });
              },
              validator: (value){
                if(value == null || value.trim().isEmpty){
                  return 'Please select a Geofencing option';
                }
              },
              items: ['Option 1', 'Option 2', 'Option 3']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('${['Close - Classroom range', 'Medium - Building range', 'Large - Campus range']
                  [['Option 1', 'Option 2', 'Option 3'].indexOf(value)]}'),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Select an GeoFencing option',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String itemName = _textEditingController.text;
                _submit();
                // Navigator.pop(context);
              },
              child: Text('Add new attendance record'),
            ),
          ],
        ),
      ),
    );
  }
}
