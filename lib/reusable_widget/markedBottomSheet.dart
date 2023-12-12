import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class markedBottomSheet extends StatefulWidget {
  const markedBottomSheet({Key? key, required this.attendanceRecordID}) : super(key: key);
  final String attendanceRecordID;

  @override
  State<markedBottomSheet> createState() => _markedBottomSheetState();
}

final _form = GlobalKey<FormState>();

class _markedBottomSheetState extends State<markedBottomSheet> {
  var _date ='';
  var _startTime ='';
  var _endTime ='';
  TextEditingController dateController = TextEditingController();
  TextEditingController startAtTimeController = TextEditingController();
  TextEditingController endAtTimeController = TextEditingController();


  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    var studentAttRecordID='';
    var attendanceCollection = await FirebaseFirestore.instance
        .collection('attendanceRecord')
        .doc(widget.attendanceRecordID)
        .get();
    var attendanceData = attendanceCollection.data() as Map<String, dynamic>;

    if(attendanceCollection.exists){

      setState(() {
        _date = attendanceData['date'];
        dateController.text = attendanceData['date'];
        _startTime = attendanceData['startAt'];
        startAtTimeController.text = attendanceData['startAt'];
        _endTime = attendanceData['endAt'];
        endAtTimeController.text = attendanceData['endAt'];
      });
    }
  }

  void _submit() async{
    var studentAttRecordID='';
    var marked = false;
    var user = FirebaseAuth.instance.currentUser;
    var userAttRecordData = await FirebaseFirestore.instance
        .collection('students').doc(user!.uid).collection('attendanceRecord').get();

    for (var doc in userAttRecordData.docs) {
      var attData = doc.data() as Map<String, dynamic>;
      var attID = attData['attendanceRecordID'];
      if(widget.attendanceRecordID == attID){
        studentAttRecordID = attData['studentAttendanceRecordID'];
      }
    }

    var studentAttRecordCollection = await FirebaseFirestore.instance
        .collection('attendanceRecord').doc(widget.attendanceRecordID).collection('studentAttendanceList')
        .doc(studentAttRecordID).get();
    var studentAttendanceData = studentAttRecordCollection.data() as Map<String, dynamic>;

    if(studentAttendanceData['attendanceStatus'] == 0){
      FirebaseFirestore.instance
          .collection('attendanceRecord').doc(widget.attendanceRecordID).collection('studentAttendanceList')
          .doc(studentAttRecordID).update({
        'attendanceStatus' : 1,
      });

      var attRecordCollection = await FirebaseFirestore.instance.collection('attendanceRecord').doc(widget.attendanceRecordID).get();
      var attendanceData = attRecordCollection.data() as Map<String, dynamic>;

      FirebaseFirestore.instance.collection('attendanceRecord').doc(widget.attendanceRecordID).update({
        'markedUser' : attendanceData['markedUser']+1,
      });
    }else{
      marked = true;
    }

    var snackBar = SnackBar(
      content: Text(marked? 'Attendance already marked!':'Mark Done'),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    dateController.clear();
    startAtTimeController.clear();
    endAtTimeController.clear();

    Navigator.pop(context);

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
              'Capture Attendance',
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
              onTap: (){
                print(widget.attendanceRecordID);
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
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // String itemName = _textEditingController.text;
                _submit();
                // Navigator.pop(context);
              },
              child: Text('Mark Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
