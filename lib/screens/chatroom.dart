import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:u_marked/reusable_widget/appBar.dart';
import 'package:u_marked/screens/chat/chatMessage.dart';
import 'package:u_marked/screens/chat/newChatMessage.dart';

class chatroom extends StatefulWidget {
  const chatroom({Key? key, required this.userID1, required this.userID2}) : super(key: key);
  final String userID1;
  final String userID2;

  @override
  State<chatroom> createState() => _chatroomState();
}

class _chatroomState extends State<chatroom> {
  String chatRoomID = '';
  String msgUser ='';

  @override
  void initState() {
    super.initState();
    List<String> participants = [widget.userID1, widget.userID2];

    // Concatenate user IDs and sort alphabetically
    List<String> sortedParticipants = List.from(participants)..sort();

    // Generate chat room ID using sorted user IDs
    chatRoomID = sortedParticipants.join('_');
    // print('Chat Room ID: $chatRoomID');
    loadData();
  }

  loadData() async{
    final user2Collection = await FirebaseFirestore.instance.collection('users').doc(widget.userID2).get();
    final user2Data = user2Collection.data() as Map<String, dynamic>;
    if(user2Data['userType'] == 1){
      final studentCollection = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.userID2).get();
      final studentData = studentCollection.data() as Map<String, dynamic>;
      setState(() {
        msgUser = studentData['name'];
      });
    }else if(user2Data['userType'] == 2){
      final lecturerCollection = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(widget.userID2).get();
      final lecturerData = lecturerCollection.data() as Map<String, dynamic>;
      setState(() {
        msgUser = lecturerData['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: chatroomAppBar(msgUser),
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.blue.shade100,
          child: Column(
            children: [
              Expanded(child: chatMessages(chatroomID: chatRoomID,)),
              newMessage(chatRoomID: chatRoomID),
              SizedBox(height: 10,)
            ],
          ),
        ),
      ),
    );
  }
}
