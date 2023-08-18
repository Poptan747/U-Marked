import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';

class UserOrdersDisplay extends StatefulWidget {

  @override
  State<UserOrdersDisplay> createState() => _UserOrdersDisplayState();
}

var _nameMap = <String, String>{};
var _subjectIDMap = <String, String>{};
var _subjectNameMap = <String, String>{};
var _timeMap = <String, String>{};
var _dateMap = <String, String>{};
var _isStudent = true;
bool _isLoading = true;
var _noData = true;
var _uID='';
var _cardTitle = <String, String>{};

class _UserOrdersDisplayState extends State<UserOrdersDisplay> {
  @override
  void initState() {
    preloadData();
    super.initState();
  }

  preloadData() async {
    _isLoading = true;
    var user = FirebaseAuth.instance.currentUser!;
    _uID = user.uid;
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    if(data['userType'] == 1){
      _isStudent = true;
    }else{
      _isStudent = false;
    }

    var classCollection = await FirebaseFirestore.instance
        .collection(_isStudent? 'students': 'lecturers')
        .doc(user.uid)
        .collection('classes')
        .get();

    if(classCollection.docs.isNotEmpty){
      setState(() {
        _noData = false;
      });

      for (var doc in classCollection.docs) {
        if (!doc.data().isEmpty){
          setState(() {
            _noData = false;
          });
          var orderData = doc.data() as Map<String, dynamic>;
          var classID = orderData['classID'];
          loadData(classID);
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

  Future<void> loadData(var classID) async {
    var classData = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classID)
        .get();

    if (classData.exists) {
      var data = classData.data() as Map<String, dynamic>;
      var subjectData = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(data['subjectID'])
          .get();

      setState(() {
        _nameMap[classID] = data['className'];
        _subjectIDMap[classID] = data['subjectID'];
        _subjectNameMap[classID] = subjectData['name'];
        _timeMap[classID] = data['lectureHour'];

        // Formatting the timestamp
        var classTimestamp = data['createAt'] as Timestamp;
        var classDateTime = classTimestamp.toDate();
        var timeFormatted = '${classDateTime.hour}:${classDateTime.minute}';

        // Formatting the date
        var dateFormatted = '${classDateTime.year}/${classDateTime.month}/${classDateTime.day}';
        // _timeMap[classID] = timeFormatted;
        _dateMap[classID] = dateFormatted;

        // Formatting card title
        if(_nameMap[classID] == null || _nameMap[classID]!.isEmpty){
          _cardTitle[classID] = (_subjectIDMap[classID]! + _subjectNameMap[classID]!)! ;
        }else{
          _cardTitle[classID] = ('${_nameMap[classID]!}\n${_subjectIDMap[classID]!}${_subjectNameMap[classID]!}')!;
        }
        _isLoading = false;
      });
    } else {
      _isLoading = false;
      print('Class data not found');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: myClassAppBar,
      body: Container(
        decoration: homeBackgroundDecoration,
        child: _isLoading? Center(child: CircularProgressIndicator(color: Colors.white,)) :
          _noData? Center(child: showEmptyClass) :
          showClassList
      ),
    );
  }
}

Text showEmptyClass = const Text(
    'No classes available.',
    style: TextStyle(
      color: Colors.white,
      fontSize: 25
    )
);

StreamBuilder showClassList = StreamBuilder(
  stream: FirebaseFirestore.instance.collection(_isStudent? 'students' : 'lecturers').doc(_uID).collection('classes').snapshots(),
  builder: (context, orderSnapshot) {
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
        var classID = orderData['classID'];
        // print(_nameMap[classID]); // Print the corresponding class name
        return GFListTile(
          padding: EdgeInsets.all(20),
          avatar:GFAvatar(
            backgroundImage: AssetImage('images/location/IEB.jpg'),
            size: GFSize.LARGE,
            shape: GFAvatarShape.standard,
          ),
          titleText: _cardTitle[classID],
          subTitleText:'${_timeMap[classID] ?? "Loading EMPTY"} \nCreate at ${_dateMap[classID] ?? "..."}',
          color: Colors.white,
          icon: const Icon(Icons.keyboard_double_arrow_right),
          onTap: (){
            print('tapped');
          },
        );
      },
    );
  },
);
