import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';


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
  var _isLoading = true;

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

    final subjectCollection = await FirebaseFirestore.instance.collection('subjects').doc(classData['subjectID']).get();
    final subjectData = await subjectCollection.data() as Map<String, dynamic>;

    final lecturerCollection = await FirebaseFirestore.instance.collection('lecturers').doc(classData['lecturerID']).get();
    final lecturerData = await lecturerCollection.data() as Map<String, dynamic>;

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
      _showDataMap['location'] = classData['locationID'];
      _showDataMap['lecturerName'] = lecturerData['name'];
      _showDataMap['lectureHour'] = classData['lectureHour'];
      _showDataMap['lectureDay'] = classData['lectureDay'];
      _isLoading = false;
      print(_showDataMap);
      print('done running');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: classDetailsAppBar(_appBarTitle,widget.classID),
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
                    child: _isLoading? Center(child: CircularProgressIndicator(),) : showClassDetail(),
                  ),
                ),
                SizedBox(height: 20,),
                Container(
                  color: Colors.white24,
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                            tabs: [
                              Tab(child: Text('Q&A',style: TextStyle(color: Colors.black),)),
                              Tab(child: Text('Attendance',style: TextStyle(color: Colors.black),)),
                            ]),
                        Container(
                          height: 500,
                          child: TabBarView(
                            children: [
                              // Content for Tab 1
                              Center(child: Text('Tab 1 content')),
                              // Content for Tab 2
                              Center(child: Text('Tab 2 content')),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Container showClassDetail(){
  final double _fontSize = 14;
return Container(
  height: 230,
  decoration: const BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    color: Colors.white,),
  child: Row(
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
            child: AspectRatio(aspectRatio: 1,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset('images/location/IEB.jpg',fit: BoxFit.cover,)
              )
            ),
        ),
      ),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Class Name: ',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w500),),
                  Expanded(child: Text('${_showDataMap["className"]}',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w300),)),
                ],
              ),
              Divider(thickness: 3),
              Row(
                children: [
                  Text('Subject Code: ',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w500),),
                  Expanded(child: Text('${_showDataMap["subjectCode"]}',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w300),)),
                ],
              ),
              Divider(thickness: 3),
              Row(
                children: [
                  Text('Subject Name: ',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w500),),
                  Expanded(child: Text('${_showDataMap["subjectName"]}',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w300),)),
                ],
              ),
              Divider(thickness: 3),
              Row(
                children: [
                  Text('Venue: ',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w500),),
                  Expanded(child: Text('${_showDataMap["location"]}',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w300),)),
                ],
              ),
              Divider(thickness: 3),
              Row(
                children: [
                  Text('Lecturer: ',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w500),),
                  Expanded(child: Text('${_showDataMap["lecturerName"]}',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w300),)),
                ],
              ),
              Divider(thickness: 3),
              Row(
                children: [
                  Text('Lecture Hour: ',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w500),),
                  Expanded(child: Text('${_showDataMap["lectureHour"]}',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w300),)),
                ],
              ),
              Divider(thickness: 3),
              Row(
                children: [
                  Text('Lecture Day: ',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w500),),
                  Text('${_showDataMap["lectureDay"]}',style: TextStyle(fontSize: _fontSize,fontWeight: FontWeight.w300),),
                ],
              ),
            ],
        ),
      )
    ],
  ),
);}
