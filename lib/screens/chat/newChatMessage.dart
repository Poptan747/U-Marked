import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class newMessage extends StatefulWidget {
  const newMessage({Key? key, required this.chatRoomID}) : super(key: key);
  final String chatRoomID;

  @override
  State<newMessage> createState() => _newMessageState();
}

class _newMessageState extends State<newMessage> {
  final _messageController = TextEditingController();

  @override
  void dispose(){
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async{
    final enteredMessage = _messageController.text;
    var chatroomID = widget.chatRoomID;

    if(enteredMessage.trim().isEmpty){
      return;
    }

    var uID = FirebaseAuth.instance.currentUser!.uid;
    var _name ='';

    final user = await FirebaseFirestore.instance.collection('users').doc(uID).get();
    final userData = user.data() as Map<String, dynamic>;
    final isStudent = userData['userType'];

    //check chatroom Collection current User
    final checkCurrentUser1ExistCollection;
    final checkCurrentUser2ExistCollection;
    var participants = chatroomID.split('_');
    var user1 = participants[0];
    var user2 = participants[1];
    var user1IsStudent;
    var user2IsStudent;

    //get collection
    final user1Collection = await FirebaseFirestore.instance.collection('users').doc(user1).get();
    final user1Data = user1Collection.data() as Map<String, dynamic>;
    final user2Collection = await FirebaseFirestore.instance.collection('users').doc(user2).get();
    final user2Data = user2Collection.data() as Map<String, dynamic>;

    //check userType
    if(user1Data['userType'] == 1){
      // student
      checkCurrentUser1ExistCollection = await FirebaseFirestore.instance
          .collection('students')
          .doc(user1)
          .collection('chatrooms').doc(chatroomID).get();
      user1IsStudent = true;
    }else{
      checkCurrentUser1ExistCollection = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(user1)
          .collection('chatrooms').doc(chatroomID).get();
      user1IsStudent = false;
    }

    if(user2Data['userType'] == 1){
      // student
      checkCurrentUser2ExistCollection = await FirebaseFirestore.instance
          .collection('students')
          .doc(user2)
          .collection('chatrooms').doc(chatroomID).get();
      user2IsStudent = true;
    }else{
      checkCurrentUser2ExistCollection = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(user2)
          .collection('chatrooms').doc(chatroomID).get();
      user2IsStudent = false;
    }

    if (!checkCurrentUser1ExistCollection.exists || !checkCurrentUser2ExistCollection.exists) {
      FirebaseFirestore.instance.collection(user1IsStudent? 'students' : 'lecturers').doc(user1).collection('chatrooms').doc(chatroomID).set({
        'chatroomID' : chatroomID,
        '_participants' : participants,
      });
      FirebaseFirestore.instance.collection(user2IsStudent? 'students' : 'lecturers').doc(user2).collection('chatrooms').doc(chatroomID).set({
        'chatroomID' : chatroomID,
        '_participants' : participants,
      });
    }

    if(isStudent == 1){
      final student = await FirebaseFirestore.instance.collection('students').doc(uID).get();
      final studentData = student.data() as Map<String, dynamic>;
      _name = studentData['name'];

    }else if(isStudent == 2){

      final lecturer = await FirebaseFirestore.instance.collection('lecturers').doc(uID).get();
      final lecturerData = lecturer.data() as Map<String, dynamic>;
      _name = lecturerData['name'];

    }

    FirebaseFirestore.instance.collection('chatrooms').doc(chatroomID).collection('message').add({
      'message' : enteredMessage,
      'userID': FirebaseAuth.instance.currentUser!.uid,
      'userName': _name,
      'createAt': Timestamp.now(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 1),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: InputDecoration(labelText: 'Send a message...'),
            ),
          ),
          IconButton(
              icon: Icon(Icons.send),
            onPressed: (){
                _submitMessage();
            },
          )
        ],
      ),
    );
  }
}