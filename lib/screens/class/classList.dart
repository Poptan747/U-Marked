import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';
import 'package:u_marked/screens/class/classDetail.dart';

class myClassList extends StatefulWidget {

  @override
  State<myClassList> createState() => _myClassListState();
}

var _nameMap = <String, String>{};
var _subjectIDMap = <String, String>{};
var _subjectNameMap = <String, String>{};
var _timeMap = <String, String>{};
var _dateMap = <String, String>{};
var _imagePathMap = <String, String>{};
var _passData = <String, dynamic>{};
var _isStudent = true;
bool _isLoading = true;
var _noData = true;
var _uID='';
var _cardTitle = <String, String>{};

class _myClassListState extends State<myClassList> {
  @override
  void initState() {
    super.initState();
    defaultData();
    preloadData();
  }

  defaultData(){
    setState(() {
      _isLoading = true;
      _nameMap.clear();
      _subjectIDMap.clear();
      _subjectNameMap.clear();
      _timeMap.clear();
      _dateMap.clear();
      _passData.clear();
      _imagePathMap.clear();
      _isStudent = true;
      _noData = true;
      _uID='';
      _cardTitle.clear();
    });
  }

  preloadData() async {
    var user;
    setState(() {
      user = FirebaseAuth.instance.currentUser!;
      _uID = user.uid;
    });

    var userCollection = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    var data = await userCollection.data() as Map<String, dynamic>;

    setState(() {
      if(data['userType'] == 1){
        _isStudent = true;
      }else{
        _isStudent = false;
      }
      _passData['isStudent'] = _isStudent;
    });


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
          _passData['classID'] = classID;
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

      var locationData = await FirebaseFirestore.instance
          .collection('locations')
          .doc(data['locationID'])
          .get();

      setState(() {
        _nameMap[classID] = data['className'];
        _subjectIDMap[classID] = data['subjectID'];
        _subjectNameMap[classID] = subjectData['name'];
        _timeMap[classID] = data['lectureHour'];
        _imagePathMap[classID] = locationData['imagePath'];

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
          _cardTitle[classID] = ('${_subjectIDMap[classID]!} ${_subjectNameMap[classID]!}')!;
        }else{
          _cardTitle[classID] = ('${_nameMap[classID]!}\n${_subjectIDMap[classID]!} ${_subjectNameMap[classID]!}')!;
        }

        if(_timeMap[classID]!.contains(',')){
          List<String> sessions = _timeMap[classID]!.split(', ');
          String formattedSessions = sessions.join('\n');
          _timeMap[classID] = formattedSessions;
        }

        _isLoading = false;
        // print('thru here again');
      });
    } else {
      _isLoading = false;
      print('Class data not found');
    }
  }

  Widget _buildClassListStream() {
    return StreamBuilder(
      // initialData: {'isStudent': _isStudent, 'uID': _uID},
      stream: FirebaseFirestore.instance.collection(_isStudent? 'students' : 'lecturers').doc(_uID).collection('classes').snapshots(),
      builder: (context, orderSnapshot) {
        // print(orderSnapshot.data!.docs.length);
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        }

        if(orderSnapshot.hasError){
          print(orderSnapshot.error);
        }

        return ListView.builder(
          itemCount: orderSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var orderData = orderSnapshot.data!.docs[index].data() as Map<String, dynamic>;
            var classID = orderData['classID'];
            bool isEmpty = false;
            if (_imagePathMap[classID] == null && _imagePathMap[classID]!.trim().isEmpty) {
              isEmpty = true;
            }
            return GFListTile(
              avatar: isEmpty ?
              const GFAvatar(
                backgroundImage: AssetImage('images/user/default_user.jpg'),
                size: GFSize.LARGE,
                shape: GFAvatarShape.standard,
              ) :
              GFAvatar(
                backgroundImage: NetworkImage(_imagePathMap[classID]!),
                size: GFSize.LARGE,
                shape: GFAvatarShape.standard,
              ),
              titleText: _cardTitle[classID],
              subTitleText:_timeMap[classID] ?? "",
              color: Colors.white,
              icon: const Icon(Icons.keyboard_double_arrow_right),
              onTap: (){
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => classDetail(classID: classID, isStudent: _isStudent,),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: myClassAppBar,
      body: Container(
        decoration: homeBackgroundDecoration,
        child: _isLoading? const Center(child: CircularProgressIndicator(color: Colors.white,)) :
          _noData? Center(child: showEmptyClass) : _buildClassListStream()
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
  // initialData: {'isStudent': _isStudent, 'uID': _uID},
  stream: FirebaseFirestore.instance.collection(_isStudent? 'students' : 'lecturers').doc(_uID).collection('classes').snapshots(),
  builder: (context, orderSnapshot) {
    if (orderSnapshot.connectionState == ConnectionState.waiting) {
      // return Center(child: Text('Loading....',style: TextStyle(color: Colors.white),));
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
        // print(orderSnapshot.data!.docs.length);
        // print(orderData);
        // print(_isStudent);
        // print(_uID);
        // print(orderSnapshot.data!.docs);
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => classDetail(classID: classID, isStudent: _isStudent,),
              ),
            );
          },
        );
      },
    );
  },
);
