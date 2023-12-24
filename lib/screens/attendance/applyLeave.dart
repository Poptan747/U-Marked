import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:u_marked/reusable_widget/appBar.dart';

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({Key? key,required this.attendanceRecordID}) : super(key: key);
  final String attendanceRecordID;

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedReason = 'None';
  File? _pickedImageFile;
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _otherReasonController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  _submit() async{
    String recordID = widget.attendanceRecordID;
    String userID = FirebaseAuth.instance.currentUser!.uid;
    String studentAttListID = '';

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
    await FirebaseFirestore.instance
        .collection('attendanceRecord')
        .doc(recordID)
        .collection('studentAttendanceList')
        .where('studentUID', isEqualTo: userID)
        .get();
    List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
    if (documents.isNotEmpty){
      for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
        studentAttListID = document.id;
      }
    }

    var studentAttCollection = await FirebaseFirestore.instance.collection('attendanceRecord')
        .doc(recordID).collection('studentAttendanceList').doc(studentAttListID).get();
    var studentAttData = await studentAttCollection.data() as Map<String, dynamic>;
    int statusType = studentAttData['attendanceStatus'];

    if(statusType == 0){
      String reason = '';
      if(_selectedReason =='Other'){
        reason = _otherReasonController.text;
      }else{
        reason = _selectedReason;
      }
      String desc = descriptionController.text;

      var attRecordCollection = await FirebaseFirestore.instance.collection('attendanceRecord').doc(recordID).get();
      var attData = await attRecordCollection.data() as Map<String, dynamic>;
      String startAt = attData['startAt'];
      String endAt = attData['endAt'];
      String attendanceSession = '$startAt - $endAt';

      FirebaseFirestore.instance.collection('attendanceRecord').doc(recordID).collection('studentAttendanceList')
          .doc(studentAttListID).update({'attendanceStatus': 5,});
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
        'startAt': startAt,
        'endAt': endAt,
        'attendanceStatus': 'Apply Leave',
        'reason': reason,
        'description' : desc.trim(),
        'applyLeave_Image' : '',
        'createAt': DateTime.now()
      }).then((value) async{
        if(_pickedImageFile!=null){
          final storageRef = FirebaseStorage.instance.ref().child('applyLeave_images').child('${value.id}.jpg');
          await storageRef.putFile(_pickedImageFile!);
          FirebaseFirestore.instance.collection('attendanceRecord')
              .doc(recordID)
              .collection('studentAttendanceList')
              .doc(studentAttListID)
              .collection('studentAttendanceSession').doc(value.id).update({
            'applyLeave_Image' :  await storageRef.getDownloadURL(),
          });
        }
      });
      setState(() {
        var snackBar = const SnackBar(
          content: Text('Apply Leave Successfully'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Navigator.pop(context);
      });
    }else{
      setState(() {
        var snackBar = const SnackBar(
          content: Text('Attendance has been confirm, no leaves can be apply'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
      return;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ApplyLeaveAppBar,
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedReason,
                              onChanged: (value) {
                                setState(() {
                                  _selectedReason = value!;
                                });
                              },
                              items: const [
                                DropdownMenuItem(value: 'None', child: Text('Select a reason')),
                                DropdownMenuItem(value: 'Vacation', child: Text('Vacation')),
                                DropdownMenuItem(value: 'Sick Leave', child: Text('Sick Leave')),
                                DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              decoration: const InputDecoration(labelText: 'Reason for Leave'),
                              validator: (value){
                                if(_selectedReason =='None'){
                                  return 'Please select a reason';
                                }
                              },
                            ),
                            if (_selectedReason == 'Other')
                              TextFormField(
                                controller: _otherReasonController,
                                decoration: const InputDecoration(labelText: 'Enter Other Reason'),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter a reason';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: descriptionController,
                                decoration: const InputDecoration(labelText: 'Enter Reason Description (Optional)'),
                              ),
                            ElevatedButton(onPressed: _pickImage, child: const Text('Upload Image (Optional)')),
                            const SizedBox(height: 5,),
                            _pickedImageFile!= null?
                            GFImageOverlay(
                              height: 500,
                              boxFit: BoxFit.contain,
                              shape: BoxShape.rectangle,
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              image: FileImage(_pickedImageFile!),
                            ) :
                            const SizedBox(),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _submit();
                                }
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
