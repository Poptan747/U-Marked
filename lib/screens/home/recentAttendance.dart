import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:u_marked/screens/attendance/attendanceDashboard.dart';

class RecentAttendance extends StatefulWidget {
  const RecentAttendance({Key? key, required this.isStudent}) : super(key: key);
  final bool isStudent;

  @override
  State<RecentAttendance> createState() => _RecentAttendanceState();
}

var _isLoading = true;
var _noData = true;
var _studentAttRecordID='';
String recordID = '';
var _nameMap = <String, String>{};
var _statusMap = <String, String>{};
var _timeMap = <String, String>{};
var _dateMap = <String, String>{};
var _iDMap = <String, String>{};

class _RecentAttendanceState extends State<RecentAttendance> {
  String userID = '';
  bool isStudent = false;

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
    _dateMap = <String, String>{};
    _iDMap = <String, String>{};
  }

  void loadData() async {
    setState(() {
      userID = FirebaseAuth.instance.currentUser!.uid;
      _isLoading = true;
      _noData = true;
    });
    try {
      var userCollection = await FirebaseFirestore.instance.collection('users').doc(userID).get();
      var data = await userCollection.data() as Map<String, dynamic>;

      if (data['userType'] == 1) {
        setState(() {
          isStudent = true;
        });
        //student
        QuerySnapshot<
            Map<String, dynamic>> querySnapshot = await FirebaseFirestore
            .instance
            .collection('students').doc(userID)
            .collection('attendanceRecord')
            .get();
        List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot
            .docs;
        if (documents.isNotEmpty) {
          for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
            var AttRecordData = document.data() as Map<String, dynamic>;
            String AttRecordID = AttRecordData['attendanceRecordID'];
            String studentAttRecordID = AttRecordData['studentAttendanceRecordID'];
            var AttCollection = await FirebaseFirestore.instance.collection(
                'attendanceRecord').doc(AttRecordID).get();
            var AttData = await AttCollection.data() as Map<String, dynamic>;

            var classCollection = await FirebaseFirestore.instance.collection(
                'classes').doc(AttData['classID']).get();
            var classData = await classCollection.data() as Map<String,
                dynamic>;

            var studentAttCollection = await FirebaseFirestore.instance
                .collection('attendanceRecord').doc(AttRecordID)
                .collection('studentAttendanceList')
                .doc(studentAttRecordID)
                .get();
            var studentAttData = await studentAttCollection.data() as Map<
                String,
                dynamic>;

            setState(() {
              _nameMap[studentAttRecordID] = classData['className'];
              _dateMap[studentAttRecordID] = AttData['date'];
              _timeMap[studentAttRecordID] =
              '${AttData['StartAt']} - ${AttData['EndAt']}';
              switch (studentAttData['attendanceStatus']) {
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
                  _statusMap[studentAttRecordID] = 'Apply Leave';
                  break;
                default:
                  _statusMap[studentAttRecordID] = 'Absent';
                  break;
              }
            });
          }
          setState(() {
            _isLoading = false;
            _noData = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _noData = true;
          });
        }
      } else {
        setState(() {
          isStudent = false;
        });
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
            .collection('attendanceRecord')
            .where('createBy', isEqualTo: userID)
            .get();
        List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
        if(documents.isNotEmpty) {
          for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
            String attRecordDataID = document.id;
            var attRecordData = document.data() as Map<String, dynamic>;
            var classCollection = await FirebaseFirestore.instance.collection('classes').doc(attRecordData['classID']).get();
            var classData = await classCollection.data() as Map<String, dynamic>;

            QuerySnapshot<Map<String, dynamic>> querySnapshotCount = await FirebaseFirestore.instance
                .collection('attendanceRecord').doc(attRecordDataID).collection('studentAttendanceList').get();
            int totalDoc = querySnapshotCount.size;
            int totalStudent = attRecordData['markedUser'];
            String displayString = '$totalStudent / $totalDoc';

            setState(() {
              _nameMap[attRecordDataID] = classData['className'];
              _dateMap[attRecordDataID] = attRecordData['date'];
              _timeMap[attRecordDataID] = displayString;
            });
          }
          setState(() {
            _isLoading = false;
            _noData = false;
          });
        }else{
          // empty
          setState(() {
            _isLoading = false;
            _noData = true;
          });
        }
      }
    }on FirebaseFirestore catch(error){
      var snackBar = SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10,10,10,10),
        margin: EdgeInsets.only(left: 20,right: 20),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height *0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Recent Attendance' , style: Theme.of(context).textTheme.titleLarge),
              const Divider(color: Colors.blue, thickness: 2, ),
              SizedBox(height: 20,),
              if(isStudent)
              _isLoading? const Center(child: CircularProgressIndicator(color: Colors.blue,)) : _buildMemberListStream(),
              if(!isStudent)
                _isLoading? const Center(child: CircularProgressIndicator(color: Colors.white,)) :_buildLecMemberListStream(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMemberListStream() {
    return Container(
      height: MediaQuery.of(context).size.height *0.50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.blue,
      ),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('students').doc(userID).collection('attendanceRecord').orderBy('createAt', descending: true).snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white,));
          }
          if(orderSnapshot.hasError){
          }

          if(!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty){
            return const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: Text('No Attendance Found'),
                    ),
                  ),
                ),
              ),
            );
          }else{
            return ListView.builder(
              itemCount: 4,
              shrinkWrap: true,
              itemBuilder: (context, index) {

                var orderData = orderSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                String stuAttRecord = orderData['studentAttendanceRecordID'];
                String recordID = orderData['attendanceRecordID'];
                String name = _nameMap[stuAttRecord] ?? 'Unknown Name';
                String date = _dateMap[stuAttRecord] ?? 'Unknown Date';
                String time = _timeMap[stuAttRecord] ?? 'Unknown Time';
                String status = _statusMap[stuAttRecord] ?? 'Unknown Status';
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: (){
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AttendanceDashboard(isStudent: isStudent,attendanceRecordID: recordID),
                            ),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            leading: getIconForAttendanceStatus(status),
                            title: Text(name),
                            subtitle: Text(date),
                            trailing: Text(status),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildLecMemberListStream() {
    return Container(
      height: MediaQuery.of(context).size.height *0.50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.blue,
      ),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('attendanceRecord').where('createBy', isEqualTo: userID).orderBy('createAt', descending: true).snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white,));
          }
          if(orderSnapshot.hasError){
          }

          if(!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty){
            return const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: Text('No Attendance Found'),
                    ),
                  ),
                ),
              ),
            );
          }else{
            return ListView.builder(
              itemCount: 4,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                String attRecordID = orderSnapshot.data!.docs[index].id;
                String name = _nameMap[attRecordID] ?? 'Unknown Name';
                String date = _dateMap[attRecordID] ?? 'Unknown Date';
                String time = _timeMap[attRecordID] ?? 'Unknown Time';
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: (){
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AttendanceDashboard(isStudent: isStudent,attendanceRecordID: attRecordID),
                            ),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(date),
                            trailing: Text(time),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

        },
      ),
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
      case 'Apply Leave':
        return Icon(Icons.edit_document); // or any other icon for 'Sick'
      default:
        return Icon(Icons.help); // or any default icon for unknown status
    }
  }
}
