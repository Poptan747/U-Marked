import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/getwidget.dart';
import 'package:intl/intl.dart';
import 'package:u_marked/reusable_widget/appBar.dart';

class ViewStudentAttendanceSession extends StatefulWidget {
  const ViewStudentAttendanceSession({Key? key, required this.attRecordID, required this.studentAttListID}) : super(key: key);
  final String studentAttListID;
  final String attRecordID;

  @override
  State<ViewStudentAttendanceSession> createState() => _ViewStudentAttendanceSessionState();
}

class _ViewStudentAttendanceSessionState extends State<ViewStudentAttendanceSession> {
  String studentID = '';
  String studentUIDBuild = '';
  String studentAttListID = '';
  String date = '';
  String time = '';
  int status = 10;
  String reason = '';
  String desc = '';
  String imageURL = '';
  bool _isLoading = true;
  bool _isEmpty = true;
  var _sessionMap = <String, String>{};
  var _statusMap = <String, String>{};
  var _timeMap = <String, String>{};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async{
    String studentAttID = widget.studentAttListID;
    String recordID = widget.attRecordID;

    try {
      var recordCollection = await FirebaseFirestore.instance
          .collection('attendanceRecord').doc(recordID).get();
      var recordData = await recordCollection.data() as Map<String, dynamic>;
      var studentAttCollection = await FirebaseFirestore.instance
          .collection('attendanceRecord').doc(recordID).collection(
          'studentAttendanceList').doc(studentAttID).get();
      var studentAttData = await studentAttCollection.data() as Map<
          String,
          dynamic>;
      String studentUID = studentAttData['studentUID'];

      var studentCollection = await FirebaseFirestore.instance
          .collection('students').doc(studentUID).get();
      var studentData = await studentCollection.data() as Map<String, dynamic>;

      QuerySnapshot<Map<String, dynamic>> sessionQuerySnapshot =
      await FirebaseFirestore.instance
          .collection('attendanceRecord')
          .doc(recordID)
          .collection('studentAttendanceList')
          .doc(studentAttID).collection('studentAttendanceSession')
          .where('studentID', isEqualTo: studentUID)
          .get();
      List<DocumentSnapshot<
          Map<String, dynamic>>> sessionDocuments = sessionQuerySnapshot.docs;

      setState(() {
        studentUIDBuild = studentUID;
        status = studentAttData['attendanceStatus'];
        studentID = studentData['studentID'];
        date = recordData['date'];
        time = '${recordData['startAt']} - ${recordData['endAt']}';

        if (sessionDocuments.isEmpty) {
          _isEmpty = true;
          _isLoading = false;
        } else {
          studentAttListID = studentAttID;
          for (DocumentSnapshot<Map<String, dynamic>> sessionDocument in sessionDocuments) {
            String studentSessionID = sessionDocument.id;
            var sessionData = sessionDocument.data() as Map<String, dynamic>;
            _sessionMap[studentUID] = sessionData['attendanceSession'];
            _statusMap[studentUID] = sessionData['attendanceStatus'];
            print(_statusMap[studentUID]);

            Timestamp firestoreTimestamp = sessionData['createAt'];
            DateTime dateTime = firestoreTimestamp.toDate();
            String formattedDate = DateFormat.yMd().add_Hm().format(dateTime);

            _timeMap[studentUID] = formattedDate;
          }

          _isEmpty = false;
          _isLoading = false;
        }
      });
      QuerySnapshot<Map<String, dynamic>> checkLeaveSnapshot = await FirebaseFirestore.instance
          .collection('attendanceRecord')
          .doc(recordID)
          .collection('studentAttendanceList')
          .doc(studentAttListID).collection('studentAttendanceSession')
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

    } on FirebaseFirestore catch (error) {
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
        return Colors.brown; // leave pending
      case 6:
        return Colors.green;// approve
      case 7:
        return Colors.red;// decline
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
        return 'Apply Leave - Pending';
      case 6:
        return 'Apply Leave - Approve';// approve
      case 7:
        return '(Absent) Apply Leave - Pending';
      default:
        return 'Unknown';
    }
  }

  _approveLeave() async{
    String recordID = widget.attRecordID;
    String studentAttID = widget.studentAttListID;

    var studentAttendanceCollection = await FirebaseFirestore.instance
        .collection('attendanceRecord').doc(recordID).collection('studentAttendanceList').doc(studentAttID).get();
    var studentAttendanceData = await studentAttendanceCollection.data() as Map<String, dynamic>;

    //0=pending 1=Present 2=Absent 3=Late 4=Leave early 5=Apply leave 6=Leave Approve 7=Leave absent
    if(studentAttendanceData['attendanceStatus'] == 5 || studentAttendanceData['attendanceStatus'] == 7){
      FirebaseFirestore.instance
          .collection('attendanceRecord')
          .doc(recordID)
          .collection('studentAttendanceList')
          .doc(studentAttID)
          .update({'attendanceStatus': 6});

      QuerySnapshot<Map<String, dynamic>> checkLeaveSnapshot = await FirebaseFirestore.instance
          .collection('attendanceRecord')
          .doc(recordID)
          .collection('studentAttendanceList')
          .doc(studentAttID).collection('studentAttendanceSession')
          .where('attendanceStatus', isEqualTo: 'Apply Leave')
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> checkLeaveDocs = checkLeaveSnapshot.docs;
      if(checkLeaveDocs.isNotEmpty){
        for (DocumentSnapshot<Map<String, dynamic>> checkLeaveDoc in checkLeaveDocs){
          var sessionData = checkLeaveDoc.data() as Map<String, dynamic>;
          String reason = sessionData['reason'];
          String approved = ' (Approved)';
          FirebaseFirestore.instance
              .collection('attendanceRecord')
              .doc(recordID)
              .collection('studentAttendanceList')
              .doc(studentAttID).collection('studentAttendanceSession').doc(checkLeaveDoc.id)
              .update({'reason' : reason + approved});
        }
      }

      setState(() {
        var snackBar = const SnackBar(
          content: Text('Leave Request has been approved'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }else{
      setState(() {
        var snackBar = const SnackBar(
          content: Text('Leave Request Already Saved!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
      return;
    }
  }

  _declineLeave() async{
    String recordID = widget.attRecordID;
    String studentAttID = widget.studentAttListID;

    var studentAttendanceCollection = await FirebaseFirestore.instance
        .collection('attendanceRecord').doc(recordID).collection('studentAttendanceList').doc(studentAttID).get();
    var studentAttendanceData = await studentAttendanceCollection.data() as Map<String, dynamic>;

    //0=pending 1=Present 2=Absent 3=Late 4=Leave early 5=Apply leave 6=Leave Approve 7=Leave absent
    if(studentAttendanceData['attendanceStatus'] == 5 || studentAttendanceData['attendanceStatus'] == 7){
      FirebaseFirestore.instance
          .collection('attendanceRecord')
          .doc(recordID)
          .collection('studentAttendanceList')
          .doc(studentAttListID)
          .update({'attendanceStatus': studentAttendanceData['attendanceStatus'] == 7 ? 2 : 0});

      QuerySnapshot<Map<String, dynamic>> checkLeaveSnapshot = await FirebaseFirestore.instance
          .collection('attendanceRecord')
          .doc(recordID)
          .collection('studentAttendanceList')
          .doc(studentAttID).collection('studentAttendanceSession')
          .where('attendanceStatus', isEqualTo: 'Apply Leave')
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> checkLeaveDocs = checkLeaveSnapshot.docs;
      if(checkLeaveDocs.isNotEmpty){
        for (DocumentSnapshot<Map<String, dynamic>> checkLeaveDoc in checkLeaveDocs){
          var sessionData = checkLeaveDoc.data() as Map<String, dynamic>;
          String reason = sessionData['reason'];
          String approved = ' (Declined)';
          FirebaseFirestore.instance
              .collection('attendanceRecord')
              .doc(recordID)
              .collection('studentAttendanceList')
              .doc(studentAttID).collection('studentAttendanceSession').doc(checkLeaveDoc.id)
              .update({'reason' : reason + approved});
        }
      }

      setState(() {
        var snackBar = const SnackBar(
          content: Text('Leave Request has been decline'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }else{
      setState(() {
        var snackBar = const SnackBar(
          content: Text('Leave Request Already Saved!'),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
      return;
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
                                  text: date,
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
                                  text: time,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              text: 'Status: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              children: [
                                const TextSpan(text: '   '),
                                TextSpan(
                                  text: getStatusString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white,
                                      background: Paint()
                                        ..strokeWidth = 20.0
                                        ..color = getStatusColor()
                                        ..style = PaintingStyle.stroke
                                        ..strokeJoin = StrokeJoin.round
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
      stream: FirebaseFirestore.instance.collection('attendanceRecord').doc(widget.attRecordID)
          .collection('studentAttendanceList').doc(widget.studentAttListID).collection('studentAttendanceSession')
          .where('studentID', isEqualTo: studentUIDBuild)
          .snapshots(),
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
            var orderData = orderSnapshot.data!.docs[index].data() as Map<String, dynamic>;

            String UID = orderData['studentID'];
            String session = _sessionMap[UID] ?? 'Unknown Session';
            String time = _timeMap[UID] ?? 'Unknown Time';
            String status = _statusMap[UID] ?? 'Unknown Status';
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
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: Text('Reason: $reason'),
              subtitle: desc.trim().isNotEmpty? Text('Description: $desc') : const Text('Description: -'),
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
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GFButton(
                    onPressed: _approveLeave,
                    shape: GFButtonShape.pills,
                    color: GFColors.SUCCESS,
                    size: GFSize.LARGE,
                    child: const Text('Approve')
                ),
                GFButton(
                    onPressed: _declineLeave,
                    shape: GFButtonShape.pills,
                    color: GFColors.DANGER,
                    size: GFSize.LARGE,
                    child: const Text('Decline')
                ),
              ],
            )
          ],
        ),
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
