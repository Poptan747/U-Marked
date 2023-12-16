import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/screens/attendance/viewStudentAttendanceSession.dart';

class studentAttendanceList extends StatefulWidget {
  const studentAttendanceList({Key? key,required this.isStudent, required this.attendanceRecordID}) : super(key: key);
  final String attendanceRecordID;
  final bool isStudent;

  @override
  State<studentAttendanceList> createState() => _studentAttendanceListState();
}

var _isLoading = true;
var _noData = true;
var _studentAttRecordID='';
String recordID = '';
var _nameMap = <String, String>{};
var _statusMap = <String, String>{};
var _timeMap = <String, String>{};
var _iDMap = <String, String>{};
var totalMemberCount = 0;

class _studentAttendanceListState extends State<studentAttendanceList> {

  @override
  void initState() {
    super.initState();
    defaultData();
    loadData();
  }

  defaultData(){
    _isLoading = true;
    _noData = true;
    _studentAttRecordID='';
    recordID = '';
    _nameMap = <String, String>{};
    _statusMap = <String, String>{};
    _timeMap = <String, String>{};
    _iDMap = <String, String>{};
  }

  void loadData() async{
    recordID = widget.attendanceRecordID;
    var studentAttCollection = await FirebaseFirestore.instance
        .collection('attendanceRecord')
        .doc(recordID)
        .collection('studentAttendanceList')
        .get();

    for (var doc in studentAttCollection.docs) {
      if (!doc.data().isEmpty){
        String studentAttRecordID = doc.id;
        var orderData = doc.data() as Map<String, dynamic>;
        var UID = orderData['studentUID'];
        setState(() {
          totalMemberCount = studentAttCollection.docs.length;
          _timeMap[studentAttRecordID] = orderData['attendanceTime'];
          switch (orderData['attendanceStatus']) {
          //0=pending 1=Present 2=Absent 3=Late 4=Leave early 5=sick
            case 0 :
              _statusMap[studentAttRecordID] = 'Pending';
              break;
            case 1:
              _statusMap[studentAttRecordID] = 'Present';
              break;
            case 2:
              _statusMap[studentAttRecordID] = 'Absent';
              break;
            case 3:
              _statusMap[studentAttRecordID] = 'Late';
              break;
            case 4:
              _statusMap[studentAttRecordID] = 'Leave Early';
              break;
            case 5:
              _statusMap[studentAttRecordID] = 'Sick Leave';
              break;
            default:
              _statusMap[studentAttRecordID] = 'Absent';
              break;
          }
          _noData = false;
        });
        loadUserData(UID, studentAttRecordID);
      }else{
        setState(() {
          _isLoading = false;
          _noData = true;
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  loadUserData(String UID, String studentAttRecordID) async{
      var studentCollection = await FirebaseFirestore.instance
          .collection('students')
          .doc(UID)
          .get();
      var studentData = studentCollection.data() as Map<String, dynamic>;
      setState(() {
        _nameMap[studentAttRecordID] = studentData['name'];
        _iDMap[studentAttRecordID] = studentData['studentID'];
      });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: studentAttendanceListAppBar(totalMemberCount),
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: _isLoading? const Center(child: CircularProgressIndicator(color: Colors.white,)) : _buildMemberListStream(),
        ),
      ),
    );
  }
}

Widget _buildMemberListStream() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance.collection('attendanceRecord').doc(recordID).collection('studentAttendanceList').snapshots(),
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
          var orderData = orderSnapshot.data!.docs[index].data() as Map<String, dynamic>;
          String stuAttRecord = orderSnapshot.data!.docs[index].id;
          var uID = orderData['uid'];
          // print(_nameMap[classID]); // Print the corresponding class name
          String name = _nameMap[stuAttRecord] ?? 'Unknown Name';
          String studentID = _iDMap[stuAttRecord] ?? 'Unknown ID';
          String status = _statusMap[stuAttRecord] ?? 'Unknown Status';
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: (){
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ViewStudentAttendanceSession(attRecordID: recordID, studentAttListID: stuAttRecord),
                  ),
                );
              },
              child: Card(
                child: ListTile(
                  leading: getIconForAttendanceStatus(status),
                  title: Text(name),
                  subtitle: Text(studentID),
                  trailing: Text(status),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget getIconForAttendanceStatus(String status) {
  switch (status) {
    case 'Pending':
      return Icon(Icons.pending_outlined); // or any other icon for 'Pending'
    case 'Present':
      return Icon(Icons.check); // or any other icon for 'Present'
    case 'Absent':
      return Icon(Icons.close); // or any other icon for 'Absent'
    case 'Late':
      return Icon(Icons.watch_later); // or any other icon for 'Late'
    case 'Leave Early':
      return Icon(Icons.exit_to_app); // or any other icon for 'Leave Early'
    case 'Sick':
      return Icon(Icons.sick_outlined); // or any other icon for 'Sick'
    default:
      return Icon(Icons.help); // or any default icon for unknown status
  }
}
