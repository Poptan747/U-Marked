import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/reusable_widget/gradientBackground.dart';
import 'package:u_marked/screens/chatroom.dart';

class inboxPage extends StatefulWidget {
  const inboxPage({Key? key}) : super(key: key);

  @override
  State<inboxPage> createState() => _inboxPageState();
}

var _userNameMap = <String, String>{};
var _userImageUrlMap = <String, String>{};
var _hasUserImageUrlMap = <String, bool>{};
var _latestMsgMap = <String, String>{};
var _latestMsgTimeMap = <String, String>{};
var _isStudent = true;
var _noData = true;
var _isLoading = true;
var _uID='';
var user1 ='';
var user2 ='';
var passUser2ID = <String, String>{};

class _inboxPageState extends State<inboxPage> {


  @override
  void initState() {
    super.initState();
    defaultData();
    loadData();
    // print('inbix');
  }

  defaultData(){
    setState(() {
      _userNameMap = <String, String>{};
      _userImageUrlMap = <String, String>{};
      _hasUserImageUrlMap = <String, bool>{};
      _latestMsgMap = <String, String>{};
      _latestMsgTimeMap = <String, String>{};
      _isStudent = true;
      _noData = true;
      _isLoading = true;
      _uID='';
      user1 ='';
      user2 ='';
      passUser2ID = <String, String>{};
    });
  }

  loadData() async{
    setState(() {
      var temp = FirebaseAuth.instance.currentUser!;
      _uID = temp.uid;
    });
    var user = FirebaseAuth.instance.currentUser!;
    var userCollection = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    var userData = userCollection.data() as Map<String, dynamic>;

    setState(() {
      if(userData['userType'] == 1){
        _isStudent = true;
      }else{
        _isStudent = false;
      }
    });

    var chatroomCollection = await FirebaseFirestore.instance.collection(_isStudent? 'students': 'lecturers')
        .doc(user.uid)
        .collection('chatrooms')
        .get();

    if(chatroomCollection.docs.isNotEmpty){
      setState(() {
        _noData = false;
      });

      for (var doc in chatroomCollection.docs) {
        if (!doc.data().isEmpty){
          setState(() {
            _noData = false;
          });
          var orderData = doc.data() as Map<String, dynamic>;
          var chatroomID = orderData['chatroomID'];

          var participants = chatroomID.split('_');
          setState(() {
            user1 = participants[0];
            user2 = participants[1];
          });
          //get collection
          final user1Collection = await FirebaseFirestore.instance.collection('users').doc(user1).get();
          final user1Data = user1Collection.data() as Map<String, dynamic>;
          final user2Collection = await FirebaseFirestore.instance.collection('users').doc(user2).get();
          final user2Data = user2Collection.data() as Map<String, dynamic>;
          var user1IsStudent;
          var user2IsStudent;
          var getUserNameCollection;

          if(user1Data['userType'] == 1){
            user1IsStudent = true;
          }else{
            user1IsStudent = false;
          }

          if(user2Data['userType'] == 1){
            user2IsStudent = true;
          }else{
            user2IsStudent = false;
          }

          if(user.uid != user1){
            getUserNameCollection = await FirebaseFirestore.instance
                .collection(user1IsStudent? 'students':'lecturers')
                .doc(user1)
                .get();
            var getUserName = await getUserNameCollection.data() as Map<String, dynamic>;
            setState(() {
              _userNameMap[chatroomID] = getUserName['name'];
              _userImageUrlMap[chatroomID] = user1Data['imagePath'];
              passUser2ID[chatroomID] = user1;
            });
          }else if(user.uid != user2){
            getUserNameCollection = await FirebaseFirestore.instance
                .collection(user2IsStudent? 'students':'lecturers')
                .doc(user2)
                .get();
            var getUserName = await getUserNameCollection.data() as Map<String, dynamic>;
            setState(() {
              _userNameMap[chatroomID] = getUserName['name'];
              _userImageUrlMap[chatroomID] = user2Data['imagePath'];
              passUser2ID[chatroomID] = user2;
            });
          }
          if(_userImageUrlMap[chatroomID]!.trim().isEmpty){
            setState(() {
              _hasUserImageUrlMap[chatroomID] = false;
              _userImageUrlMap[chatroomID] = '';
            });
          }else{
            _hasUserImageUrlMap[chatroomID] = true;
          }
          loadInboxData(chatroomID);
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
    }else{
      setState(() {
        _isLoading = false;
        _noData = true;
      });
    }
  }

  loadInboxData(String chatroomID) async{
    var chatroomData = await FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatroomID)
        .get();

    if (chatroomData.exists) {
      var data = chatroomData.data() as Map<String, dynamic>;

      setState(() {
        _latestMsgMap[chatroomID] = data['latestMessage'];

        var msgTimestamp = data['latestMessageTimestamp'] as Timestamp;
        var msgDateTime = msgTimestamp.toDate();
        var timeFormatted = '${msgDateTime.hour}:${msgDateTime.minute}';

        _latestMsgTimeMap[chatroomID] = timeFormatted;

        print('thru here again');
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print('chatroom data not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: inboxAppBar,
      body: Container(
        decoration: homeBackgroundDecoration,
        height: MediaQuery.of(context).size.height,
        child: _isLoading? Center(child: CircularProgressIndicator(color: Colors.white,)) :
        _noData? Center(child: showEmptyClass) : _buildClassListStream(),
      ),
    );
  }
}

Text showEmptyClass = const Text(
    'No Chatroom Available.',
    style: TextStyle(
        color: Colors.white,
        fontSize: 25
    )
);

Widget _buildClassListStream() {
  return StreamBuilder(
    // initialData: {'isStudent': _isStudent, 'uID': _uID},
    stream: FirebaseFirestore.instance.collection(_isStudent? 'students' : 'lecturers').doc(_uID).collection('chatrooms').snapshots(),
    builder: (context, orderSnapshot) {
      // print(orderSnapshot.data!.docs.length);
      if (orderSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if(orderSnapshot.hasError){
        print(orderSnapshot.error);
      }

      return ListView.builder(
        itemCount: orderSnapshot.data!.docs.length,
        itemBuilder: (context, index) {
          List<bool> hasURL = List.generate(orderSnapshot.data!.docs.length, (index) => false);
          var orderData = orderSnapshot.data!.docs[index].data() as Map<String, dynamic>;
          var chatroomID = orderData['chatroomID'];
          String imageUrl = _userImageUrlMap[chatroomID]?.trim() ?? '';
          return GFListTile(
            padding: EdgeInsets.all(20),
            avatar: imageUrl.isNotEmpty ?
            GFAvatar(
              backgroundImage: NetworkImage(imageUrl),
              size: GFSize.LARGE,
              shape: GFAvatarShape.standard,
            ):
            const GFAvatar(
              backgroundImage: AssetImage('images/user/default_user.jpg'),
              size: GFSize.LARGE,
              shape: GFAvatarShape.standard,
            ),
            titleText: _userNameMap[chatroomID],
            subTitleText:'${_latestMsgMap[chatroomID] ?? "Loading EMPTY"} \nCreate at ${_latestMsgTimeMap[chatroomID] ?? "..."}',
            color: Colors.white,
            icon: const Icon(Icons.keyboard_double_arrow_right),
            onTap: (){
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => chatroom(userID1: _uID, userID2: passUser2ID[chatroomID].toString()),
                ),
              );
            },
          );
        },
      );
    },
  );
}
