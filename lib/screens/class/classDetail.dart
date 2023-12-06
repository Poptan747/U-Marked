import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';
import 'package:u_marked/screens/attendance.dart';
import 'package:u_marked/screens/class/memberList.dart';


class classDetail extends StatefulWidget {

  const classDetail({Key? key, required this.classID, required this.isStudent}) : super(key: key);
  final String classID;
  final bool isStudent;

  @override
  State<classDetail> createState() => _classDetailState();
}
var _showDataMap = <String, String>{};

class _classDetailState extends State<classDetail> {

  var _appBarTitle ='';
  var _lecID='';
  var _isLoading = true;
  String formattedLecHour = '';

  @override
  void initState() {
    super.initState();
    loadData();
    print(widget.classID);
  }

  loadData() async{
    var _classID = widget.classID;
    var _isStudent = widget.isStudent;
    var _className ='';


    final classCollection = await FirebaseFirestore.instance.collection('classes').doc(_classID).get();
    final classData = await classCollection.data() as Map<String, dynamic>;

    final locationCollection = await FirebaseFirestore.instance.collection('locations').doc(classData['locationID']).get();
    final locationData = await locationCollection.data() as Map<String, dynamic>;

    final subjectCollection = await FirebaseFirestore.instance.collection('subjects').doc(classData['subjectID']).get();
    final subjectData = await subjectCollection.data() as Map<String, dynamic>;

    List<String> outputList = classData['lecturerID'].split(',');
    List<String> lecturerNames = [];
    for(var lecID in outputList){
      String lecDocID = '';
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('lecturers')
          .where('lecturerID', isEqualTo: lecID)
          .get();
      List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
      for (DocumentSnapshot<Map<String, dynamic>> document in documents) {
        lecDocID = document.id;
      }
      var lecturerCollection = await FirebaseFirestore.instance.collection('lecturers').doc(lecDocID).get();
      var lecturerData = await lecturerCollection.data() as Map<String, dynamic>;
      String lecName = lecturerData['name'];
      lecturerNames.add(lecName);

      if(classData['lectureHour'].contains(',')){
        List<String> sessions = classData['lectureHour'].split(', ');
        String formattedSessions = sessions.join('\n');
        formattedLecHour = formattedSessions;
      }else{
        formattedLecHour = classData['lectureHour'];
      }
    }

    if(classData['className'] == null || classData['className'].isEmpty){
      _className = classData['subjectID'] + subjectData['name'];
    }else{
      _className = classData['className'];
    }
    setState(() {
      _appBarTitle = _className;
      _showDataMap['className'] = _className;
      _showDataMap['subjectCode'] = classData['subjectID'];
      _showDataMap['subjectName'] = subjectData['name'];
      _showDataMap['location'] = locationData['roomNo'];
      _showDataMap['imagePath'] = locationData['imagePath'];
      _showDataMap['lecturerName'] = lecturerNames.join(', ');
      _lecID = classData['lecturerID'];
      _showDataMap['lectureHour'] = formattedLecHour;
      // _showDataMap['lectureDay'] = classData['lectureDay'];
      _isLoading = false;
      // print(_showDataMap);
      // print('done running');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: classDetailsAppBar(_appBarTitle,context),
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: SingleChildScrollView(
            child: Column(
              children: [
                FractionallySizedBox(
                  widthFactor: 0.95,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _isLoading? const Center(child: CircularProgressIndicator(),) : showClassDetail(),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Colors.blue.shade100,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 30,
                      children: [
                        itemDashboard('Posts', CupertinoIcons.bubble_left_bubble_right_fill, Colors.deepOrange, 1),
                        itemDashboard('Attendances', CupertinoIcons.check_mark_circled, Colors.green, 2),
                        itemDashboard('Member List', CupertinoIcons.person_2, Colors.purple, 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10)
              ],
            ),
          ),
        ),
      ),
    );
  }

  itemDashboard(String title, IconData iconData, Color background , int index) => GestureDetector(
    onTap: (){
      switch (index) {
        case 1:
        // do something
          break;
        case 2:
        // do something else attendanceWidget
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => attendanceWidget(isStudent: widget.isStudent,classID: widget.classID),
            ),
          );
          break;
        case 3 :
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => memberList(classID: widget.classID, lecturerID: _lecID),
            ),
          );
          break;
      }
    },
    child: Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                offset: const Offset(0, 5),
                color: Theme.of(context).primaryColor.withOpacity(.2),
                spreadRadius: 2,
                blurRadius: 5
            )
          ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white)
          ),
          const SizedBox(height: 8),
          Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleMedium)
        ],
      ),
    ),
  );
}

Container showClassDetail(){
  ScrollController _scrollController = ScrollController();
return Container(
  height: 230,
  decoration: const BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    color: Colors.white,),
  child: _showDataMap['imagePath']!.trim().isEmpty ? GFImageOverlay(
    height: 200,
    width: 300,
    image: AssetImage('images/location/IEB.jpg'),
    borderRadius: const BorderRadius.all(Radius.circular(10)),
    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scrollbar(
        controller: _scrollController,
        isAlwaysShown: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text('Class Name: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["className"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              Divider(thickness: 3),
              Row(
                children: [
                  const Text('Subject Code: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["subjectCode"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              const Divider(thickness: 3),
              Row(
                children: [
                  const Text('Subject Name: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["subjectName"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              const Divider(thickness: 3),
              Row(
                children: [
                  const Text('Venue: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["location"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              const Divider(thickness: 3),
              Row(
                children: [
                  const Text('Lecturer: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["lecturerName"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              const Divider(thickness: 3),
              Row(
                children: [
                  const Text('Lecture Hour: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["lectureHour"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ) :
  GFImageOverlay(
    height: 200,
    width: 300,
    image: NetworkImage(_showDataMap['imagePath']!),
    borderRadius: const BorderRadius.all(Radius.circular(10)),
    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scrollbar(
        controller: _scrollController,
        isAlwaysShown: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text('Class Name: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["className"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              Divider(thickness: 3),
              Row(
                children: [
                  const Text('Subject Code: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["subjectCode"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              const Divider(thickness: 3),
              Row(
                children: [
                  const Text('Subject Name: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["subjectName"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              const Divider(thickness: 3),
              Row(
                children: [
                  const Text('Venue: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["location"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              const Divider(thickness: 3),
              Row(
                children: [
                  const Text('Lecturer: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["lecturerName"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
              const Divider(thickness: 3),
              Row(
                children: [
                  const Text('Lecture Hour: ',style: TextStyle(color: GFColors.LIGHT),),
                  Expanded(child: Text('${_showDataMap["lectureHour"]}',style: const TextStyle(color: GFColors.WHITE),)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);}
