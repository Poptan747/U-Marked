import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/getwidget.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/bottomSheet.dart';
import 'package:u_marked/reusable_widget/markedBottomSheet.dart';
import 'package:u_marked/screens/attendance/attendanceDashboard.dart';

class attendanceWidget extends StatefulWidget {
  const attendanceWidget({Key? key, required this.isStudent, required this.classID}) : super(key: key);
  final bool isStudent;
  final String classID;

  @override
  State<attendanceWidget> createState() => _attendanceWidgetState();
}
var _dateMap = <String, String>{};
var _startTimeMap = <String, String>{};
var _endTimeMap = <String, String>{};
var _totalMemberMap = <String, String>{};
var _totalMarkedMemberMap = <String, String>{};
bool _isLoading = true;
var _noData = true;
DateTime today = DateTime.now();
String formattedDate = DateFormat('EEE, MMM d, yyyy').format(today);

class _attendanceWidgetState extends State<attendanceWidget> {

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async{
    var attendanceCollection = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classID)
        .collection('attendanceRecord')
        .get();

    if(attendanceCollection.docs.isNotEmpty){
      setState(() {
        _noData = false;
      });

      for (var doc in attendanceCollection.docs) {
        if (!doc.data().isEmpty){
          setState(() {
            _noData = false;
          });
          var orderData = doc.data() as Map<String, dynamic>;
          var attendanceRecordID = orderData['attendanceRecordID'];
          // _passData['classID'] = classID;
          loadRecordData(attendanceRecordID);
        }else{
          setState(() {
            _isLoading = false;
            _noData = true;
          });
        }
      }
    }else{
      setState(() {
        _isLoading = false;
        _noData = true;
      });
    }
  }

  loadRecordData(String attendanceRecordID) async{
    var attendanceRecordData = await FirebaseFirestore.instance
        .collection('attendanceRecord')
        .doc(attendanceRecordID)
        .get();

    var attendanceMember = await FirebaseFirestore.instance
        .collection('attendanceRecord')
        .doc(attendanceRecordID).collection('studentAttendanceList')
        .get();
    var totalAttendanceMember = attendanceMember.size.toString();

    if (attendanceRecordData.exists) {
      var data = attendanceRecordData.data() as Map<String, dynamic>;

      setState(() {
        _dateMap[attendanceRecordID] = data['date'];
        _startTimeMap[attendanceRecordID] = data['startAt'];
        _endTimeMap[attendanceRecordID] = data['endAt'];
        _totalMemberMap[attendanceRecordID] = totalAttendanceMember;
        _totalMarkedMemberMap[attendanceRecordID] = data['markedUser'].toString();
        _isLoading = false;
        print('thru here again');
      });
    } else {
      _isLoading = false;
      print('Class data not found');
    }
  }

  void _onDaySelected(DateTime day, DateTime focusedDay){
    setState(() {
      today = day;
      formattedDate = DateFormat('EEE, MMM d, yyyy').format(today);
      print(formattedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AttendanceAppBar,
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: today,
                    selectedDayPredicate: (day) => isSameDay(day,today),
                    onDaySelected: _onDaySelected,
                  ),
                ),
                Divider(),
                Visibility(
                  visible: !widget.isStudent,
                  child: GFButton(
                      shape: GFButtonShape.pills,
                      elevation: 2,
                      size: GFSize.LARGE,
                      child: Text('Collect Attendance'),
                      onPressed: (){
                        widget.isStudent? null:_showBottomSheet(context,widget.classID);
                      }),
                ),
                _isLoading? const Center(child: CircularProgressIndicator(color: Colors.white,)) :
                _noData? Center(child: showEmptyClass) : _buildAttendanceListStream()
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildAttendanceListStream() {
    return Expanded(
      child: StreamBuilder(
        // initialData: {'isStudent': _isStudent, 'uID': _uID},
        stream: FirebaseFirestore.instance.collection('classes').doc(widget.classID)
            .collection('attendanceRecord').where('date', isEqualTo: formattedDate)
            .snapshots(),
        builder: (context, orderSnapshot) {
          // print(orderSnapshot.data!.docs.length);
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text('Loading....',style: TextStyle(color: Colors.white),));
          }

          if(orderSnapshot.hasError){
            print(orderSnapshot.error);
          }

          return ListView.builder(
            itemCount: orderSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var orderData = orderSnapshot.data!.docs[index].data() as Map<String, dynamic>;
              var attendanceRecordID = orderData['attendanceRecordID'];
              return GFListTile(
                padding: EdgeInsets.all(20),
                titleText: _dateMap[attendanceRecordID],
                subTitleText:'From ${_startTimeMap[attendanceRecordID]} to ${_endTimeMap[attendanceRecordID]} \n${_totalMarkedMemberMap[attendanceRecordID]} / ${_totalMemberMap[attendanceRecordID]} marked',
                color: Colors.white,
                // icon: const Icon(Icons.keyboard_double_arrow_right),
                onTap: (){
                  if(widget.isStudent){
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AttendanceDashboard(isStudent: widget.isStudent,attendanceRecordID: attendanceRecordID),
                      ),
                    );
                  }else{
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AttendanceDashboard(isStudent: widget.isStudent,attendanceRecordID: attendanceRecordID),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}


Text showEmptyClass = const Text(
    'No Attendance available.',
    style: TextStyle(
        color: Colors.white,
        fontSize: 25
    )
);


void _showBottomSheet(BuildContext context, String classID) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FormBottomSheet(classID:classID); // Display the FormBottomSheet widget
    },
  );
}

void _showMarkedBottomSheet(BuildContext context, String RecordID) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return markedBottomSheet(attendanceRecordID: RecordID); // Display the FormBottomSheet widget
    },
  );
}

