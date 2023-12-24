import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:u_marked/reusable_widget/appBar.dart';

class ViewMyAttendanceSessionPage extends StatefulWidget {
  const ViewMyAttendanceSessionPage({Key? key,required this.isStudent, required this.attendanceRecordID, required this.date, required this.time}) : super(key: key);
  final String date;
  final String time;
  final String attendanceRecordID;
  final bool isStudent;

  @override
  State<ViewMyAttendanceSessionPage> createState() => _ViewMyAttendanceSessionPageState();
}

class _ViewMyAttendanceSessionPageState extends State<ViewMyAttendanceSessionPage> {
  String studentID = '';
  String studentAttListID = '';
  int status = 10;
  bool _isLoading = true;
  bool _isEmpty = true;
  String reason = '';
  String desc = '';
  String imageURL = '';
  var _sessionMap = <String, String>{};
  var _statusMap = <String, String>{};
  var _timeMap = <String, String>{};

  @override
  void initState() {
    super.initState();
    defaultData();
    loadData();
  }

  defaultData(){
    _isLoading = true;
    _isEmpty = true;
    _sessionMap = <String, String>{};
    _statusMap = <String, String>{};
    _timeMap = <String, String>{};
  }

  loadData () async {
    String recordID = widget.attendanceRecordID;
    String userID = FirebaseAuth.instance.currentUser!.uid;
    String studentAttListDocID = '';

    try {
      //student data
      var studentCollection = await FirebaseFirestore.instance
          .collection('students').doc(userID).get();
      var studentData = await studentCollection.data() as Map<String, dynamic>;

      //student att list
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
          studentAttListDocID = document.id;
        }

        //student att data
        var studentAttLisCollection = await FirebaseFirestore.instance
            .collection('attendanceRecord').doc(recordID)
            .collection('studentAttendanceList').doc(studentAttListDocID).get();
        var studentAttData = await studentAttLisCollection.data() as Map<String, dynamic>;

        // student att session list
        QuerySnapshot<Map<String, dynamic>> sessionQuerySnapshot =
        await FirebaseFirestore.instance
            .collection('attendanceRecord')
            .doc(recordID)
            .collection('studentAttendanceList')
            .doc(studentAttListDocID).collection('studentAttendanceSession')
            .get();
        List<DocumentSnapshot<
            Map<String, dynamic>>> sessionDocuments = sessionQuerySnapshot.docs;

        setState(() {
          studentID = studentData['studentID'];
          status = studentAttData['attendanceStatus'];
          if (sessionDocuments.isEmpty) {
            _isEmpty = true;
            _isLoading = false;
          } else {
            studentAttListID = studentAttListDocID;
            for (DocumentSnapshot<
                Map<String, dynamic>> sessionDocument in sessionDocuments) {
              String studentSessionID = sessionDocument.id;
              var sessionData = sessionDocument.data() as Map<String, dynamic>;
              _sessionMap[studentSessionID] = sessionData['attendanceSession'];
              _statusMap[studentSessionID] = sessionData['attendanceStatus'];

              Timestamp firestoreTimestamp = sessionData['createAt'];
              DateTime dateTime = firestoreTimestamp.toDate();
              String formattedDate = DateFormat.yMd().add_Hm().format(dateTime);

              _timeMap[studentSessionID] = formattedDate;
            }
          }
        });
        QuerySnapshot<Map<String, dynamic>> checkLeaveSnapshot = await FirebaseFirestore.instance
            .collection('attendanceRecord')
            .doc(recordID)
            .collection('studentAttendanceList')
            .doc(studentAttListDocID).collection('studentAttendanceSession')
            .where('attendanceStatus', isEqualTo: 'Apply Leave')
            .get();
        List<DocumentSnapshot<Map<String, dynamic>>> checkLeaveDocs = checkLeaveSnapshot.docs;
        if(checkLeaveDocs.isNotEmpty){
          for (DocumentSnapshot<Map<String, dynamic>> checkLeaveDoc in checkLeaveDocs){
            var sessionData = checkLeaveDoc.data() as Map<String, dynamic>;
            setState(() {
              reason = sessionData['reason'];
              desc = sessionData['description'];
              imageURL = sessionData['applyLeave_Image'];
            });
          }
        }
        setState(() {
          _isEmpty = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }on FirebaseFirestore catch (error) {
      print(error);
      var snackBar = SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

  }

  Color getStatusColor() {
    switch (status) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.brown;
      default:
        return Colors.black;
    }
  }

  String getStatusString() {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Present';
      case 2:
        return 'Absent';
      case 3:
        return 'Late';
      case 4:
        return 'Leave Early';
      case 5:
        return 'Apply Leave';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: attendanceSessionAppBar,
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Attendance Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: 'Student ID: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: studentID,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: 'Date: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: widget.date,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: 'Time: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: widget.time,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: 'Status: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: getStatusString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                      color: getStatusColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(thickness: 3,color: Colors.white,),
              Expanded(
                child: _isEmpty? _emptySession() :
                _isLoading? const Center(child: CircularProgressIndicator(color: Colors.white,))
                    : _buildMemberListStream(studentAttListID),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberListStream(String sessionID) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('attendanceRecord').doc(widget.attendanceRecordID)
          .collection('studentAttendanceList').doc(sessionID).collection('studentAttendanceSession').snapshots(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Loading....',style: TextStyle(color: Colors.white),));
        }
        if(orderSnapshot.hasError){
          print(orderSnapshot.error);
        }
        return ListView.builder(
          itemCount: orderSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            String stuAttRecord = orderSnapshot.data!.docs[index].id;
            // print(_nameMap[classID]); // Print the corresponding class name
            String session = _sessionMap[stuAttRecord] ?? 'Unknown Session';
            String time = _timeMap[stuAttRecord] ?? 'Unknown Time';
            String status = _statusMap[stuAttRecord] ?? 'Unknown Status';
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      // leading: getIconForAttendanceStatus(status),
                      title: Text(session),
                      subtitle: Text('Capture At $time'),
                      trailing: Text(status),
                    ),
                  ),
                  if(status == 'Apply Leave')
                    _applyLeaveSession(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _applyLeaveSession(){
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: [
          Card(
            child: ListTile(
              title: Text('Reason: $reason'),
              subtitle: desc.trim().isNotEmpty? Text('Description: $desc') : const Text('Description: -'),
            ),
          ),
          if(imageURL.trim().isNotEmpty)
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                imageURL,
                height: 500,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySession(){
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Card(
        child: ListTile(
          title: Text('No Attendance Session Found'),
        ),
      ),
    );
  }
}
