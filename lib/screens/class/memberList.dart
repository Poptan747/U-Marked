import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/screens/chatroom.dart';

class memberList extends StatefulWidget {
  const memberList({Key? key, required this.classID, required this.lecturerID}) : super(key: key);
  final String classID;
  final String lecturerID;

  @override
  State<memberList> createState() => _memberListState();
}

var _isLoading = true;
var _noData = true;
var _classID='';
var _lecturerMap = <String, String>{};
var _nameMap = <String, String>{};
var _studentIDMap = <String, String>{};
var _batchMap = <String, String>{};
var _currentUser = FirebaseAuth.instance.currentUser!;

class _memberListState extends State<memberList> {

  @override
  void initState() {
    super.initState();
    defaultData();
    loadData();
  }

  defaultData(){
    _currentUser = FirebaseAuth.instance.currentUser!;
    _isLoading = true;
    _noData = true;
    _classID='';
    _lecturerMap = <String, String>{};
    _nameMap = <String, String>{};
    _studentIDMap = <String, String>{};
    _batchMap = <String, String>{};
  }

  loadData() async{
    _classID = widget.classID;
    var lecturerCollection = await FirebaseFirestore.instance
        .collection('lecturers')
        .doc(widget.lecturerID)
        .get();
    var lecturerData = lecturerCollection.data() as Map<String, dynamic>;

    setState(() {
      _lecturerMap['name'] = lecturerData['name'];
      _lecturerMap['id'] = lecturerData['lecturerID'];
    });

    var memberCollection = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classID)
        .collection('members')
        .get();

    for (var doc in memberCollection.docs) {
      if (!doc.data().isEmpty){
        setState(() {
          _noData = false;
        });
        var orderData = doc.data() as Map<String, dynamic>;
        var UID = orderData['uid'];
        loadUserData(UID);
      }else{
        setState(() {
          _isLoading = false;
          _noData = true;
        });
      }
    }

  }

  loadUserData(String UID) async{
    var userCollection = await FirebaseFirestore.instance
        .collection('students')
        .doc(UID)
        .get();
    var orderData = userCollection.data() as Map<String, dynamic>;

    setState(() {
      _nameMap[UID] = orderData['name'];
      _studentIDMap[UID] = orderData['studentID'];
      _batchMap[UID] = orderData['batch'];
      _isLoading = false;
    });
    // print(orderData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: memberListAppBar,
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: Column(
            children: [
              GFListTile(
                padding: const EdgeInsets.all(20),
                titleText: _lecturerMap['name'],
                subTitleText:_lecturerMap['id'],
                color: Colors.white,
                icon: _currentUser.uid == widget.lecturerID? const Icon(Icons.account_circle,color: Colors.black) :
                      const Icon(Icons.message,color: Colors.blue),
                onTap: (){
                  if(_currentUser.uid == widget.lecturerID){
                    print('NOPE');
                    print(_currentUser.uid);
                  }else{
                    print('tapped');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => chatroom(userID1: _currentUser.uid, userID2: widget.lecturerID),
                      ),
                    );
                  }
                },
              ),
              const Divider(thickness: 5,),
              Expanded(
                  child: _isLoading? const Center(child: CircularProgressIndicator(color: Colors.white,)) : _buildMemberListStream()
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildMemberListStream() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance.collection('classes').doc(_classID).collection('members').snapshots(),
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
          var uID = orderData['uid'];
          // print(_nameMap[classID]); // Print the corresponding class name
          return GFListTile(
            padding: const EdgeInsets.all(20),
            titleText: _nameMap[uID],
            subTitleText:'${_studentIDMap[uID] ?? "Loading EMPTY"} \n${_batchMap[uID] ?? "..."}',
            color: Colors.white,
            icon: _currentUser.uid == uID ? Icon(Icons.account_circle,color: Colors.black,) : Icon(Icons.chat,color: Colors.blue,),
            onTap: (){
              if(_currentUser.uid == uID){
                print('NOPE');
                print(_currentUser.uid);
              }else{
                print('tapped');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => chatroom(userID1: _currentUser.uid, userID2: uID),
                  ),
                );
              }
            },
          );
        },
      );
    },
  );
}

StreamBuilder showMemberList = StreamBuilder(
  stream: FirebaseFirestore.instance.collection('classes').doc(_classID).collection('members').snapshots(),
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
        var uID = orderData['uid'];
        // print(_nameMap[classID]); // Print the corresponding class name
        return GFListTile(
          padding: const EdgeInsets.all(20),
          titleText: _nameMap[uID],
          subTitleText:'${_studentIDMap[uID] ?? "Loading EMPTY"} \n${_batchMap[uID] ?? "..."}',
          color: Colors.white,
          icon: _currentUser.uid == uID ? Icon(Icons.account_circle,color: Colors.black,) : Icon(Icons.chat,color: Colors.blue,),
          onTap: (){
            if(_currentUser.uid == uID){
              print('NOPE');
              print(_currentUser.uid);
            }else{
              print('tapped');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => chatroom(userID1: _currentUser.uid, userID2: uID),
                ),
              );
            }
          },
        );
      },
    );
  },
);
